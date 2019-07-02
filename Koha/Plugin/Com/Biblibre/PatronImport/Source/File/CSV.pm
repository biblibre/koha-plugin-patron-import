package Koha::Plugin::Com::Biblibre::PatronImport::Source::File::CSV;

use Modern::Perl;
use Koha::Plugin::Com::Biblibre::PatronImport::Source::File;
use Text::CSV;
use vars qw( @ISA ); @ISA = qw( Koha::Plugin::Com::Biblibre::PatronImport::Source::File );

sub _next {
    my $self = shift;
    my $fh = $self->{fh};
    return if eof($fh);

    my $config = $self->{import}{config};

    my $csv = Text::CSV->new($config->{setup}->{'file-csv'}) or die "Cannot use CSV: ".Text::CSV->error_diag ();
    unless ( $self->{header} ) {
        $self->{header} = $csv->getline($fh);
        return if eof($fh);
    }

    my $row = $csv->getline($fh);
    my %data;
    $data{$_} = shift @$row for @{ $self->{header} };
    return \%data;
}
1;
