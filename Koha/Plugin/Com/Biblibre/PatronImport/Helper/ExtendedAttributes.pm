package Koha::Plugin::Com::Biblibre::PatronImport::Helper::ExtendedAttributes;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

use Modern::Perl;

use Koha::Patron::Attribute::Types;

sub save_according_to_rules {
    my ($attribute, $rules, $patron_orm) = @_;
    my $ext_attr_orm = $patron_orm->extended_attributes
	->search( { 'me.code' => $attribute->{code} } )
	->filter_by_branch_limitations;

        my $count = $ext_attr_orm->count;
        my $exists = 0;

        while ( my $a = $ext_attr_orm->next ) {
            if ( $a->attribute eq $attribute->{attribute} ) {
                $exists = 1;
            }
        }

        if ( $count == 0 ) {
            return add($patron_orm, $attribute);
        }

        if ( $count == 1 && $rules->{behaviour_one_value} eq 'update' ) {
            $ext_attr_orm->delete;
            return add($patron_orm, $attribute);
        }

        if ( $count == 1 && $rules->{behaviour_one_value} eq 'add' && $rules->{repeatable} == 1 ) {
            return add($patron_orm, $attribute);
        }

        if ( $count == 1 && $rules->{behaviour_one_value} eq 'add_dedup'
            && $rules->{repeatable} == 1 && !$exists ) {

            return add($patron_orm, $attribute);
        }

        if ( $count == 1 && $rules->{behaviour_one_value} eq 'nothing' ) {
            return '';
        }

        if ( $count > 1 && $rules->{behaviour_many_values} eq 'add'
            && $rules->{repeatable} == 1 ) {

            return add($patron_orm, $attribute);
        }

        if ( $count > 1 && $rules->{behaviour_many_values} eq 'add_dedup'
            && $rules->{repeatable} == 1 && !$exists ) {

            return add($patron_orm, $attribute);
        }
}

sub add {
    my ($patron_orm, $attribute) = @_;

    eval { $patron_orm->add_extended_attribute($attribute); };
    if ($@) {
        return "Unable to add attribute: $@";
    }
    return '';
}

sub save {
    my ($attribute, $patron_orm) = @_;
    $patron_orm->extended_attributes
        ->search( { 'me.code' => $attribute->{code} } )
	->filter_by_branch_limitations->delete;

    eval { $patron_orm->add_extended_attribute($attribute); };
    if ($@) {
	return "Unable to add attribute: $@";
    }

    return '';
}

1;
