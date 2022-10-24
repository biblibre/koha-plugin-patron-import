package Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron;

use Modern::Perl;

use C4::Context;
use C4::Members;
use Koha::Patron;
use Koha::Patrons;
use Koha::Patron::Attribute::Types;
use Koha::Patron::Debarments;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::MessagePreferences;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::ExtendedAttributes;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons qw( :DEFAULT );

sub new {
    my $class = shift;
    my $this = {};
    return bless $this, $class;
}

sub _debug {
    my $this = shift;
    print Data::Dumper::Dumper($this);
}

sub get {
    my ($this, $field) = @_;

    my $field_type = valid_field($field);
    if ($field_type == 1) {
        return $this->{$field};
    }

    if ($field_type == 2) {
        return $this->_get_xattr($field)
    }
}

sub _get_xattr {
    my ($this, $field) = @_;

    foreach my $attr (@{ $this->{xattr} }) {
        if ($attr->{code} eq $field) {
            return $attr->{attribute};
        }
    }
}

sub as_text {
    my $this = shift;
    my $out;

    $out .= $this->_as_text . $this->_xattr_as_text;
    return $out;
}

sub _as_text {
    my $this = shift;
    my $out;

    foreach my $key ( sort keys %$this ) {
        if ( $key ne "xattr" && $key ne "permissions" && $key ne "setup" ) {
            my $value = $this->{ $key } // '';
            $out .= "$key: $value\n";
        }
    }
    return $out;
}

sub _xattr_as_text {
    my $this = shift;
    my $out;

    $out .= "Extended attributes:\n" if $this->{xattr};
    foreach my $xattr ( @{ $this->{xattr} } ) {
        my $code = $xattr->{code};
        my $value = $xattr->{attribute} || '';
        $out .= "    - $code: $value\n" if $value ne '';
    }
    $out .= "\n";
    return $out;
}

sub addXattributes {
    my ($this, $to_add) = @_;

    if ( $to_add ) {
        foreach my $code ( keys %$to_add ) {

            my $value = $to_add->{ $code };

            if ( ref($value) eq "ARRAY" ) {
                push @{ $this->{xattr} }, { attribute => $_, code => $code } for @$value;
            } else {
                push @{ $this->{xattr} }, { attribute => $value, code => $code };
            }
        }
    }
}

sub is_xattr {
    my $xattr = shift;

    my $attribute_type = Koha::Patron::Attribute::Types->find($xattr);

    if ( $attribute_type ) {
        return 1;
    }

    return 0;
}

sub xattr_to_protect {
    my ( $borrowernumber, $attr_code ) = @_;

    my $dbh = C4::Context->dbh;
    my $query = "SELECT attribute FROM borrower_attributes WHERE borrowernumber=? AND code=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($borrowernumber, $attr_code);
    my $result = $sth->fetchrow_array;

    return 1 if is_set($result);
    return 0;
}


sub Xattributes {
    my ($this, $attributes) = @_;

    if ( $attributes ) {
        $this->{xattr} = [];
        $this->addXattributes($attributes);
    } else {
        print $this->_xattr_as_text;
    }
}

sub to_koha {
    my ($this, $import) = @_;

    $this->{import} = $import;

    my $conf = $this->{import}{config};

    my %patron = $this->_unbless;

    # Make a hash with patron informations. ( Use matchingpoint values ).
    # This informations are used in log system.
    my $patron_info = {};
    foreach ( @{ $conf->{matchingpoint} } ) {
        $patron_info->{$_} = $this->{$_} || 'UNDEFINED';
    }

    # In addition to 'matchingpoint', a plugin can override patron_info or add
    # values (From extended attributes in exemple).

    Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_patron_info', [\%patron, $patron_info]);

    # Finally, make a string for logging.
    my $patron_info_str = join(", ", map { "$_: $patron_info->{$_}" } keys %$patron_info);
    $patron_info_str ||= "";

    if ($this->to_skip()) {
        $this->{status} = 'skipped';
        $import->{logger}->Add(
            'info',
            "$patron_info_str has been skipped",
            '',
            \%patron
        );
        return;
    }

    # Extract patron extended attributes
    my $extended_attributes = _clean_xattr($patron{xattr});
    delete $patron{xattr};

    # Verifying date
    $this->_check_dates_format(\%patron);

    # Empty branchcode and categorycode
    # if it is not correct.
    for (qw/branchcode categorycode/) {
        my $func = "_check_$_";
        unless ( $this->$func($patron{$_}) ) {
            $patron{$_} = '';
        }
    }

    $this->_set_default(\%patron);

    # Re verifying branchcode categorycode
    for (qw/branchcode categorycode/) {
        unless ($patron{$_}) {
            $this->{status} = 'error';
            $import->{logger}->Add(
                'error',
                "borrower doesn't have a correct $_. You should add a default value for this field. i.e '$_: INC'",
                '',
                \%patron
            );
            return '';
        }
    }

    my $borrowernumber = $this->_patron_exists;

    if ( $import->{dry_run} ) {
       $this->{status} = $borrowernumber ? 'updated' : 'new';
       return;
    }

    # Check for message preferences protection.
    my $protect_message_preferences = 0;
    foreach ( @{ $conf->{protected} } ) {
	if ( $_ eq '[message_preferences]' ) {
	    $protect_message_preferences = 1;
	}
    }

    if ($borrowernumber && $conf->{createonly}) {
        return 0;
    }
    my $exists = 0;
    if ( $borrowernumber ) {
        $exists = 1;

        # Deletion rules.
        my $deletion_rules = $conf->{deletions} || ();
        foreach my $rule (@$deletion_rules) {
	    if ($this->_rule_match_delete($rule, \%patron)) {
		my $to_delete = Koha::Patrons->find( $borrowernumber );

		if ( my $charges = $to_delete->account->non_issues_charges ) {
		    $this->{status} = 'error';
		    $import->{logger}->Add(
			'error',
			"Failed to delete patron $borrowernumber: patron has $charges in fines",
			'',
			\%patron
		    );
		    return;
		}

		my $checkouts = $to_delete->checkouts;
		if ( my $count_checkouts = $checkouts->count() ) {
		    $this->{status} = 'error';
		    $import->{logger}->Add(
			'error',
			"Failed to delete patron $borrowernumber: patron has $count_checkouts checkouts",
			'',
			\%patron
		    );
		    return;
		}

		$to_delete->delete();
		$this->{status} = 'deleted';
		$import->{logger}->Add(
		    'info',
		    "$patron_info_str has been deleted",
		    '',
		    \%patron
		);
		return;
	    }
        }

        # Here we keep original patron because some fields
        # we need in logger could be deleted if protected.
        my %kept_patron = %patron;

        # If patron exists some fields should not be replaced.
        foreach ( @{ $conf->{protected} } ) {
            if ( is_xattr($_) ) {
                if ( xattr_to_protect($borrowernumber, $_) ) {
                    foreach my $attr (@{ $extended_attributes }) {
                        if ($attr->{code} eq $_) {
                            $attr->{delete} = 1;
                        }
                    }
                }
            }
            elsif ( $this->to_protect( $borrowernumber, $_ ) ) {
                delete $patron{ $_ };
                delete $this->{ $_ };
            }
        }

        # Clean extended_attributes from removed entries.
        @{ $extended_attributes } = grep { !defined $_->{delete} } @$extended_attributes;

        # Remove from hash empty fields that are not explicitely allowed to be
        # erased.
        unless (ref $conf->{erasable} eq 'ARRAY') {
            $conf->{erasable} = [];
        }
        foreach my $field (keys %patron) {
            $patron{$field} //= '';
            my $value = $patron{$field};

            next if ref $value ne '';

            if ($value eq '' && !in_array($conf->{erasable}, $field))
            {
                delete $patron{$field};
                delete $this->{$field};
            }
        }

        my $stored_patron = Koha::Patrons->find( $borrowernumber );
        my $stored_extended_attributes = $stored_patron->extended_attributes()->unblessed;

        Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins(
            'patron_import_patron_update',
            [\%patron, $extended_attributes, $stored_patron, $stored_extended_attributes]
        );

        # Exclude rules based on koha account.
        my $rules = $conf->{exclusions} || ();
        foreach my $rule (@$rules) {
            next if $rule->{origin} eq 'ext';
            if ($this->_rule_match_exclusion($rule, $stored_patron->unblessed(), $stored_extended_attributes)) {
                $this->{status} = 'skipped';
                $import->{logger}->Add(
                    'info',
                    "$patron_info_str has been skipped (from koha)",
                    '',
                    \%patron
                );
                return;
            }
        }

        eval { my $success = $stored_patron->set(\%patron)->store; };
        if ( $@ ) {
            $this->{status} = 'error';
            $import->{logger}->Add(
                'error',
                "Fail to update patron: $@",
                $borrowernumber,
                \%kept_patron
            );
            return;
        }

        # Update password.
        my $userid = $stored_patron->userid();
        if ($userid && $patron{password}) {
            # Koha < 19.11
            if ($stored_patron->can('update_password')) {
                $stored_patron->update_password($userid, $patron{password});
            }
            # Koha >= 19.11
            if ($stored_patron->can('set_password')) {
                $stored_patron->set_password({ password => $patron{password} });
            }
        }

        $import->{logger}->Add(
            'success',
            "Patron successfully updated",
            $borrowernumber,
            \%kept_patron
        );

        $this->{'status'} = 'updated';
        Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_patron_updated', $borrowernumber);
    } else {
        Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_patron_create', [\%patron, $extended_attributes]);

        # Generate a cardnumber.
        if ( ( $conf->{autocardnumber} eq 'gen_if_empty' && !$this->{cardnumber}) || $conf->{autocardnumber} eq 'gen' ) {
            $patron{cardnumber} = $this->genCardnumber();
            $import->{logger}->Add(
                'info',
                "Generated a new cardnumber",
                '',
                \%patron
            );
        }

        eval { $borrowernumber = Koha::Patron->new(\%patron)->store->borrowernumber; };
        if ( $@ ) {
            $import->{logger}->Add(
                'error',
                "Fail to create patron: $@",
                '',
                \%patron
            );
            $this->{'status'} = 'error';
            return;
        }

        $import->{logger}->Add(
            'success',
            "Patron successfully created",
            $borrowernumber,
            \%patron
        );

        my $result = $this->add_debarment($borrowernumber);
        if ( $result && $result eq 'error' ) {
            $import->{logger}->Add(
                'error',
                "Unable to add debarment for this patron",
                $borrowernumber,
                \%patron
            );
            $this->{'status'} = 'error';
        }

        if ( $result && $result eq 'ok' ) {
            $import->{logger}->Add(
                'info',
                "Debarment added",
                $borrowernumber,
                \%patron
            );
        }

        $this->{'status'} = 'new';
        Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_patron_created', $borrowernumber);
    }

    unless ($borrowernumber) {
        $this->{'status'} = 'error';
        return;
    }

    $this->{'borrowernumber'} = $borrowernumber;
    my $patron_orm = Koha::Patrons->find($borrowernumber);

    if ( $exists == 0 or $protect_message_preferences == 0 ) {
        Koha::Plugin::Com::Biblibre::PatronImport::Helper::MessagePreferences::set($borrowernumber, \%patron);
    }

    if ( $extended_attributes ) {
	my $extended_attributes_rules = $conf->{extendedattributes};
        foreach my $attribute ( @$extended_attributes ) {
	    my $attr_rules = $extended_attributes_rules->{ $attribute->{code} } || '';

	    my $error;
	    unless ( $attr_rules ) {
		$error = Koha::Plugin::Com::Biblibre::PatronImport::Helper::ExtendedAttributes::save($attribute, $patron_orm);
	    }

	    if ( $attr_rules ) {
		$error = Koha::Plugin::Com::Biblibre::PatronImport::Helper::ExtendedAttributes::save_according_to_rules($attribute, $attr_rules, $patron_orm);
	    }

            if ($error) {
                $import->{logger}->Add(
                    'error',
                    "Unable to add attribute: $@",
                    $borrowernumber,
                    \%patron
                );
                $this->{'status'} = 'error';
            }
        }
    }

    $borrowernumber;
}

sub add_debarment {
    my ($self, $borrowernumber) = @_;

    my $debarment_conf = $self->{import}{config}{debarments};

    if ( $debarment_conf->{suspend} ) {
        eval { Koha::Patron::Debarments::AddDebarment(
                {   borrowernumber => $borrowernumber,
                    type           => 'MANUAL',
                    comment        => $debarment_conf->{'comment'},
                    expiration     => $debarment_conf->{expiration},
                }
            );
        };

        if ( $@ ) {
            return 'error';
        }

        return 'ok';
    }
}

sub is_protected {
    my ($self, $key) = @_;

    my $conf = $self->{import}{config};

    return in_array($conf->{protected}, $key);
}

sub _unbless {
    my $this = shift;

    my %unblessed;
    foreach my $key ( keys %$this ) {
        next if $key eq 'import';

        $unblessed{ $key } = $this->{ $key } || '';

        # Trim whitespaces
        $unblessed{$key} =~ s/^\s+//;
        $unblessed{$key} =~ s/\s+$//;
    }
    return %unblessed;
}

sub genCardnumber {
    my $this = shift;

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(
        "select max(cast(cardnumber as signed)) from borrowers"
    );
    $sth->execute;
    my ($result) = $sth->fetchrow;
    return $result + 1;
}

sub _clean_xattr {
    my $xattr = shift;
    my $new_xattr;

    foreach my $attr ( @$xattr ) {
        if (is_empty($attr->{attribute})) {
            next;
        }

        unless (is_xattr($attr->{code})) {
            next;
        }

        push @{ $new_xattr }, $attr;
    }
    return $new_xattr;
}

sub _patron_exists {
    my $this = shift;

    my $conf = $this->{import}{config};

    return 0 unless scalar(@{ $conf->{matchingpoint} });

    my $dbh = C4::Context->dbh;

    my $query = q{
        SELECT DISTINCT(borrowers.borrowernumber)
        FROM borrowers
          LEFT JOIN borrower_attributes USING (borrowernumber)
        WHERE 1=1
    };

    my @sqlargs;
    foreach my $mpoint ( @{ $conf->{matchingpoint} } ) {
        die "Invalid matching point: '$mpoint'. Field doesn't exist." unless valid_field($mpoint);
        if ( defined $this->{$mpoint} ) {
            $query .= " AND $mpoint = ? ";
            push @sqlargs, $this->{$mpoint};
        } else {
            my ($value) = map { $_->{code} =~ $mpoint ? $_->{attribute} : () }  @{ $this->{xattr} };
            $query .= ' AND (code = ? and attribute = ?) ';
            push @sqlargs, $mpoint, $value;
        }
    }

    my $sth = $dbh->prepare($query);
    $sth->execute(@sqlargs);
    my $result = $sth->fetchrow_array;
    return $result;
}

sub _set_default {
    my ($this, $patron) = @_;

    my $conf = $this->{import}{config};

    my $defaults = $conf->{default};

    foreach my $default_field ( keys %$defaults ) {
        unless ($patron->{$default_field}) {
            $patron->{$default_field} = $defaults->{$default_field};
            $this->{$default_field} = $defaults->{$default_field};
            my $replaced = $patron->{$default_field};
            $this->{import}->{logger}->Add(
                'info',
                "$default_field Replaced with $replaced",
                '',
                $patron
            );
        }
    }
}

sub _check_dates_format {
    my ( $this, $patron ) = @_;

    my $date_error = 0;
    foreach (qw/dateofbirth dateenrolled dateexpiry/) {
        if ( $patron->{ $_ } ) {
            unless ( $patron->{ $_ } =~ /^\d{4}-\d{2}-\d{2}$/ ) {
                my $replace = $this->_fix_date( $patron->{ $_ } );
                $patron->{ $_ } = $replace;
                $this->{ $_ } = $replace;
                $this->{import}->{logger}->Add(
                    'info',
                    "Invalid date format. Replaced by $replace",
                    '',
                    $patron
                );
            }
        }
    }
    return 1 unless $date_error;
    return 0;
}

sub _fix_date {
    my ($this, $date) = @_;

    my $conf = $this->{import}{config};

    my $date_format = $conf->{setup}->{date_format} || '';

    return '0000-00-00' unless $date_format;

    if ( $date_format =~ /^d(.)m(.)Y$/ ) {
        my @dmY = split($1, $date);
        return $dmY[2] . '-' . $dmY[1] . '-' . $dmY[0];
    }

    return '0000-00-00';
}

sub _check_categorycode {
    my ($this, $categorycode) = @_;

    return 0 unless $categorycode;

    my $categories_rs = Koha::Patron::Categories->search();
    while ( my $category = $categories_rs->next() ) {
        return 1 if $category->categorycode eq $categorycode;
    }

    return 0;
}

sub _check_branchcode {
    my ($this, $branchcode) = @_;

    return 0 unless $branchcode;

    my $libraries_rs = Koha::Libraries->search();
    while ( my $library = $libraries_rs->next() ) {
        return 1 if $library->branchcode eq $branchcode;
    }

    return 0;
}

sub to_skip {
    my ($this, $patron) = @_;

    Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_to_skip', [$this]);

    if ( defined($this->{skip}) && $this->{skip} ) {
        return 1;
    }

    my $conf = $this->{import}{config};

    my $rules = $conf->{exclusions} || ();
    foreach my $rule (@$rules) {
        next if $rule->{origin} eq 'koha';
        return 1 if $this->_rule_match($rule);
    }
    return 0;
}

sub _rule_match {
    my ($this, $rule, $patron) = @_;

    unless(keys %{ $rule->{fields} }) {
        return 0;
    }

    unless ($patron) {
        $patron = $this;
    }

    foreach my $field (keys %{ $rule->{fields} }) {
        if (is_set($patron->{$field}) && $patron->{$field} ne $rule->{fields}->{$field}) {
            return 0;
        }
        elsif (is_empty($patron->{$field}) && $rule->{fields}->{$field} eq '') {
            return 0;
        }
    }
    return 1;
}

sub _rule_match_delete {
    my ($this, $rule, $patron) = @_;

    unless(keys %{ $rule->{fields} }) {
        return 0;
    }

    unless ($patron) {
        $patron = $this;
    }

    foreach my $field (keys %{ $rule->{fields} }) {
	unless ( defined($patron->{$field}) ) {
            return 0;
	}

	if ( $patron->{$field} eq '' ) {
            return 0;
	}

        if ( $patron->{$field} ne $rule->{fields}->{$field} ) {
            return 0;
        }
    }
    return 1;
}

sub _rule_match_exclusion {
    my ($this, $rule, $patron, $extended_attributes) = @_;

    unless(keys %{ $rule->{fields} }) {
        return 0;
    }

    my $data = $patron;
    foreach my $attr ( @$extended_attributes ) {
        $data->{ $attr->{code} } = $attr->{attribute};
    }

    foreach my $field (keys %{ $rule->{fields} }) {
        unless ( defined($data->{$field}) ) {
            return 0;
        }

        if ( $data->{$field} eq '' ) {
            return 0;
        }

        if ( $data->{$field} ne $rule->{fields}->{$field} ) {
            return 0;
        }
    }
    return 1;
}

sub to_protect {
    my ( $this, $borrowernumber, $field ) = @_;
    return if $field eq 'permissions';
    return if $field eq '[message_preferences]';

    my $dbh = C4::Context->dbh;
    my $query = "SELECT $field FROM borrowers WHERE borrowernumber=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($borrowernumber);
    my $result = $sth->fetchrow_array;

    return 1 if is_set($result);
    return 0;
}

1;
