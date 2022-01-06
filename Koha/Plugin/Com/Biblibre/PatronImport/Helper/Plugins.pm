package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins;

use Modern::Perl;
use Koha::Plugins;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;

our $available_plugin_methods = [
    'patron_import_mapping_preprocess',
    'patron_import_mapping_postprocess',
    'patron_import_patron_info',
    'patron_import_patron_update',
    'patron_import_patron_updated',
    'patron_import_patron_create',
    'patron_import_patron_created',
    'patron_import_to_skip',
];

sub callPlugins {
    my ($method, $args) = @_;

    my $config = get_conf();
    my $plugins_enabled = $config->{plugins_enabled};

    my @args = ();
    if (ref($args) ne 'ARRAY') {
        push @args, $args;
    }
    else {
        @args = @{ $args };
    }

    my @plugins = Koha::Plugins->new()->GetPlugins({
        method => $method,
    });

    foreach my $plugin ( @plugins ) {
        unless ( defined($plugins_enabled->{ $plugin->{metadata}{class} }) ) {
            next;
        }
        $plugin->$method(@args);
    }
}

sub get_candidates {

    my $candidates;
    foreach my $method ( @$available_plugin_methods ) {
        my @plugins = Koha::Plugins->new()->GetPlugins({
            method => $method,
        });
        foreach my $plugin ( @plugins ) {
            if ( defined($candidates->{ $plugin->{metadata}{name} }) ) {
                push @{ $candidates->{ $plugin->{metadata}{name} }{methods} }, $method;
                next;
            }

            $candidates->{ $plugin->{metadata}{name} } = {
                class => $plugin->{metadata}{class},
                methods => [ $method ],
                enabled => 0
            };
        }
    }
    return $candidates;
}

1;
