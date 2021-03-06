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
        next unless exists $data->{ $source };

        my $value = $data->{ $source };
        $value = applyTransformationPlugins( $transformationplugins, $target, $value );
        $borrower->{ $target } = mapvalues( $valuesmapping, $target, $value );
    }

    # Calling postprocess hook.
    Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::callPlugins('patron_import_mapping_postprocess', $borrower);

    # Map borrower with patron object.
    map_patron_object($patron, $borrower);

    return $patron;
}

sub applyTransformationPlugins {
    my ($transformationplugins, $target, $value) = @_;

    my $target_plugins = $transformationplugins->{$target};
    unless ($target_plugins) {
        return $value;
    }

    no strict;
    foreach my $name ( @$target_plugins ) {
        my $tr_plugin = Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::get($name);

        next unless $tr_plugin;
        my $package = $tr_plugin->{package};
        $value = &{ "${package}::transform" }( $value );
    }
    use strict;

    return $value;
}

sub mapvalues {
    my ($valuemapping, $transformedkey, $value) = @_;

    if ( !defined($value) || $value eq '' ) {
        return $value;
    }

    if ( my $v = $valuemapping->{$transformedkey} ) {
        my $rv;
        ref $v eq "HASH" and $rv = $v->{$value} and return $rv;
        # No key in transformation for $value.
        return $value;
    } else {
        # No transformation key for $value.
        return $value;
    }
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
