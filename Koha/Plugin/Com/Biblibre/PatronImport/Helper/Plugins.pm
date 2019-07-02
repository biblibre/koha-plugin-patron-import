package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins;

use Modern::Perl;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;

sub GetPlugins {
    my $conf = get_conf;
    my @plugins;
    foreach my $name ( keys %{ $conf->{setup}->{plugins} } ) {
        my $plugin_info = $conf->{setup}->{plugins}->{ $name };
        my $path = $plugin_info->{path};
        my $file = $plugin_info->{file};

        if (-e "$path/$file") {
            $plugin_info->{require} = "$path/$file";
            $plugin_info->{name} = $name;
            push @plugins, $plugin_info;
        }
    }
    return \@plugins;
}

sub callPlugins {
    my ($hook, $args) = @_;
    my $plugins = GetPlugins();

    foreach my $plugin ( @$plugins ) {
        eval{ require $plugin->{require}; };
        if ($@) {
            warn "Unable to use " . $plugin->{name} . " plugin: $@";
            next;
        }
        my $package = $plugin->{package};
        if ( defined( $package->can($hook) ) ) {
            execHook($package, $hook, $args);
        }
    }
}

sub execHook {
    no strict 'refs';
    my ( $ns, $sub, $args ) = @_;

    my @args = ();
    if (ref($args) ne 'ARRAY') {
        push @args, $args;
    }
    else {
        @args = @{ $args };
    }

    *{"$ns\::$sub"}->( @args );
}

1;
