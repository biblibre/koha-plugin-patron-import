package Koha::Plugin::Com::Biblibre::PatronImport::Helper::ExtendedAttributes;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw();

use Modern::Perl;

use Koha::Patron::Attribute::Types;

sub process {
    my ( $attributes, $rules, $patron_orm ) = @_;

    my $patron_attrs = _get_patron_xattrs($patron_orm);
    my %new_xattrs;

    foreach my $attribute (@$attributes) {
        my $code  = $attribute->{code};
        my $value = $attribute->{attribute};

        if ( $rules->{$code} && $patron_attrs->{$code} ) {
            my $count = scalar @{ $patron_attrs->{$code} };

            if ( $count == 1 ) {
                if ( $rules->{$code}->{behaviour_one_value} eq 'update' ) {
                    push @{ $new_xattrs{$code} }, $value;
                }
                if (   $rules->{$code}->{behaviour_one_value} eq 'add'
                    && $rules->{$code}->{repeatable} == 1 )
                {
                    push @{ $patron_attrs->{$code} }, $value;
                    $new_xattrs{$code} = $patron_attrs->{$code};
                }
                if (   $rules->{$code}->{behaviour_one_value} eq 'add_dedup'
                    && $rules->{$code}->{repeatable} == 1 )
                {
                    push @{ $patron_attrs->{$code} }, $value
                      if 0 ==
                      ( grep( /^$value$/, @{ $patron_attrs->{$code} } ) );
                    $new_xattrs{$code} = $patron_attrs->{$code};
                }
            }
            if ( $count > 1 ) {
                if ( $rules->{$code}->{behaviour_many_values} eq 'update' ) {
                    push @{ $new_xattrs{$code} }, $value;
                }
                if (   $rules->{$code}->{behaviour_many_values} eq 'add'
                    && $rules->{$code}->{repeatable} == 1 )
                {
                    push @{ $patron_attrs->{$code} }, $value;
                    $new_xattrs{$code} = $patron_attrs->{$code};
                }
                if (   $rules->{$code}->{behaviour_many_values} eq 'add_dedup'
                    && $rules->{$code}->{repeatable} == 1 )
                {
                    push @{ $patron_attrs->{$code} }, $value
                      if 0 ==
                      ( grep( /^$value$/, @{ $patron_attrs->{$code} } ) );
                    $new_xattrs{$code} = $patron_attrs->{$code};
                }
            }
        }
        else {
            push @{ $new_xattrs{$code} }, $value;
        }
    }

    $patron_orm->extended_attributes->search( {} )->delete;

    foreach my $code ( keys %new_xattrs ) {
        my $attributes = $new_xattrs{$code};
        foreach my $attribute ( @{$attributes} ) {
            eval {
                $patron_orm->add_extended_attribute(
                    { code => $code, attribute => $attribute } );
            };
            if ($@) {
                return "$code => $attribute Unable to add attribute: $@";
            }
        }
    }
}

sub _get_patron_xattrs {
    my $patron_orm = shift;
    my %xattrs;

    my $ext_attr_orm = $patron_orm->extended_attributes->search( {} );
    while ( my $a = $ext_attr_orm->next ) {
        push( @{ $xattrs{ $a->code } }, $a->attribute ) if $a->attribute;
    }
    return \%xattrs;
}

1;
