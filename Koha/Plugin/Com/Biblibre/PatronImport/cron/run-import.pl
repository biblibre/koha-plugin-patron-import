#! /usr/bin/perl

use Modern::Perl;
use Getopt::Long;

use C4::Context;
use Koha::Plugins;
use Koha::Plugin::Com::Biblibre::PatronImport;

my ( $from, $import_id, $dry_run );
GetOptions (
    'from|f=s' => \$from,
    'import-id|i=i' => \$import_id,
    'dry-run' => \$dry_run,
);

my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new({
    enable_plugins  => 1,
    import_id       => $import_id,
    from            => $from,
    dry_run         => $dry_run
});

$plugin->run_import();
