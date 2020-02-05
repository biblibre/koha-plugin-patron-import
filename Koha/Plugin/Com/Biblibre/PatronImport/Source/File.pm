package Koha::Plugin::Com::Biblibre::PatronImport::Source::File;

use Modern::Perl;
use Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Mapping;
use YAML;
use LWP::UserAgent;
use DateTime;

sub in {
    my ( $class, $import ) = @_;

    my $fh;
    my $from = $import->{from};
    $from ||= resolve_file($import->{config}{setup});

    my $this = {
        fh              => $fh,
        import          => $import,
        header          => 0,
        unable_to_run   => 0,
    };

    # Open a local file.
    unless (open $fh, "<:encoding(utf8)", "$from") {
        $this->{unable_to_run} = 'File not found';
    }

    $this->{fh} = $fh;

    return( bless $this, $class );

}

sub next {
    my $this = shift;
    $this->{patronnum}++;
    my $patron = $this->_next() or return;
    return process_mapping($patron);
}

sub resolve_file {
    my $setup = shift;

    my $flow = $setup->{'flow-type'};
    my $pattern = $setup->{ $flow }{'file_path'};

    my $today = DateTime->now;
    my ($year, $month, $day) = split('-', $today->ymd);

    $pattern =~ s/<year>/$year/;
    $pattern =~ s/<month>/$month/;
    $pattern =~ s/<day>/$day/;

    return $pattern;
}

1;
