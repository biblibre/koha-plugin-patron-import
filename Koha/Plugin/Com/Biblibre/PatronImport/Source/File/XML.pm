package Koha::Plugin::Com::Biblibre::PatronImport::Source::File::XML;

use Koha::Plugin::Com::Biblibre::PatronImport::Source::File;
use XML::Simple;
use vars qw( @ISA ); @ISA = qw( Koha::Plugin::Com::Biblibre::PatronImport::Source::File );

sub _next {
    my $this = shift;
    my $fh = $this->{fh};
    return if eof($fh);

    my $xmlsimple = XML::Simple->new();
    my $data = $xmlsimple->XMLin($fh, ContentKey => 'patron');
    print Data::Dumper::Dumper($data);
}
