package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Mapping;

use Modern::Perl;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons qw( PatronFields );
use Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins;

our @ISA = qw(Exporter);
our @EXPORT = qw(process_mapping);

my $borrowers_fields;

BEGIN {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->column_info(undef, undef, 'borrowers', '%');
    $sth->execute;
    $borrowers_fields = $sth->fetchall_hashref('COLUMN_NAME');
}

sub process_mapping {
    my $data = shift;

    my $conf = get_conf;

    my $borrower = {};
    my $patron = Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron->new();
    my ($map, $valuesmapping, $transformationplugins)
        = @{$conf}{qw(map valuesmapping transformationplugins)};

    # Calling preprocess hook.
    Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_mapping_preprocess', [$data, $borrower]);

    # Build reverse mapping : keys are fields in target ($borrower),
    # values are fields in source ($data)
    # This is to avoid random behaviour depending on the order of keys returned
    # by `keys`
    my @keys = keys %$data;
    my %rmap;
    @rmap{ @keys } = @keys;
    foreach my $source (keys %$map) {
        delete $rmap{ $source };

        my $targets = $map->{$source};
        $targets = [ $targets ] unless ref $targets eq 'ARRAY';

        foreach my $target (@$targets) {
            $rmap{ $target } = $source;
        }
    }

    # Transform data.
    foreach my $target ( keys %rmap ) {
        my $source = $rmap{ $target };

        my $value = GetMappedField($data, $source);
        $value = applyTransformationPlugins( $transformationplugins, $target, $value );
        $borrower->{ $target } = mapvalues( $valuesmapping, $target, $value );
    }

    # Calling postprocess hook.
    Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_mapping_postprocess', $borrower);

    # Map borrower with patron object.
    map_patron_object($patron, $borrower);

    return $patron;
}

sub GetMappedField {
    my ($data, $source) = @_;

    unless ($source =~ /<</) {
        my $value = $data->{ $source } || '';
        return $value;
    }

    my $value = $source;
    while ($source =~ /<<([a-zA-Z0-9\|]+)>>/g) {
        my $token = $1;

        if ($token =~ /\|\|/) {
            my @tokens = split('\|\|', $token);
            my $val = '';
            foreach my $t ( @tokens ) {
                if ($data->{$t}) {
                    $val = $data->{$t};
                    last;
                }
            }
            $token =~ s/\|\|/\\|\\|/g; # Escape pipes to match them.
            $value =~ s/<<$token>>/$val/g;
            return $value;
        }

        my $val = $data->{$token} || '';
        $value =~ s/<<$token>>/$val/g;
    }
    return $value;
}

sub applyTransformationPlugins {
    my ($transformationplugins, $target, $value) = @_;

    my $target_plugins = $transformationplugins->{$target};
    unless ($target_plugins) {
        return $value;
    }

    foreach my $name ( @$target_plugins ) {
        my $tr_plugin = Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::get($name);

        next unless $tr_plugin;
        my $package = $tr_plugin->{package};
        my $plugin_path = $package;
        $plugin_path =~ s/::/\//g;
        $plugin_path =~ s/$/.pm/;
        no strict 'refs';
        require $plugin_path;
        $value = &{ "${package}::transform" }( $value );
        use strict;
    }

    return $value;
}

sub mapvalues {
    my ($valuemapping, $transformedkey, $value) = @_;

    if ( !defined($value) || $value eq '' ) {
        return $value;
    }

    my $v = $valuemapping->{ $transformedkey };
    foreach my $input ( keys %$v ) {
        my $rule = $v->{$input};
        my $output = $rule->{output};
        my $operator = $rule->{operator} || '';

        unless ( $operator ) {
            return $output if $input eq $value;
        }

        if ( $operator eq 'start' ) {
            return $output if $value =~ /^$input/;
        }

        if ( $operator eq 'contains' ) {
            return $output if $value =~ /$input/;
        }
    }

    return $value;
}

sub map_patron_object {
    my ($patron, $borrower) = @_;

    foreach my $key ( keys %$borrower ) {
        if ( exists $borrowers_fields->{ $key } ) {
            $patron->{ $key } = $borrower->{ $key };
        } else {
            push @{ $patron->{xattr} }, { code => $key, attribute => $borrower->{ $key } };
        }
    }
}

1;
