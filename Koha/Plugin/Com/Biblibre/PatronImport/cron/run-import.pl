#! /usr/bin/perl

use Modern::Perl;
use Getopt::Long;

use C4::Context;
use Koha::Plugins;
use Koha::Plugin::Com::Biblibre::PatronImport;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

my ( $from, $import_id, $dry_run, $info_logs, $success_log );
GetOptions (
    'from|f=s' => \$from,
    'import-id|i=i' => \$import_id,
    'dry-run' => \$dry_run,
    'info-logs' => \$info_logs,
    'success-log' => \$success_log
);

if (!$import_id && $from) {
    print "You can't specify a source (--from|s) without import id (--import-id|i).\n";
    exit;
}

my $imports_params;
if ($import_id) {
    $imports_params->{id} = $import_id;
}

my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new();

my $imports = GetFromTable($plugin->{import_table}, $imports_params);

foreach my $import ( @$imports ) {
    $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new({
        enable_plugins  => 1,
        import_id       => $import->{id},
        from            => $from,
        dry_run         => $dry_run,
        info_logs       => $info_logs,
        success_log     => $success_log
    });

    $plugin->run_import();
}
