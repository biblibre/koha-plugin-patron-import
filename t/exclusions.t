#!/usr/bin/perl

use Modern::Perl;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../";

use Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron;

# 1) Patron should not be skipped with rule on XATTR
my $patron = Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron->new();

is (ref($patron),'Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron');

$patron->{firstname} = 'Thibaud';
$patron->{surname} = 'Guillot';

$patron->addXattributes({FOO => 'bar'});
$patron->addXattributes({COMPOSANTE => 'MEDECINE-UCA'});
$patron->{import}{config}{exclusions} = [
    {
        'origin' => 'ext',
        'fields' => {
            'COMPOSANTE' => 'MED-UCA'
        }
    }
];

is($patron->to_skip(), 0, 'Patron Thibaud must not be skipped on XATTR');

# 2) Patron should not be skipped with rule on field
push @{ $patron->{import}{config}{exclusions} },
    {
        'origin' => 'ext',
        'fields' => {
            'surname' => 'Arnaud'
        }
    };

is($patron->to_skip(), 0, 'Patron Thibaud must not be skipped');

$patron = Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron->new();

$patron->{firstname} = 'Alex';
$patron->{surname} = 'Arnaud';

$patron->{import}{config}{exclusions} = [
    {
        'origin' => 'ext',
        'fields' => {
            'surname' => 'Plop'
        }
    }
];

is($patron->to_skip(), 0, 'Patron Alex must not be skipped');
push @{ $patron->{import}{config}{exclusions} },
    {
        'origin' => 'ext',
        'fields' => {
            'firstname' => 'Alex'
        }
    };

is($patron->to_skip(), 1, 'Patron Alex must be skipped');

# 3) Multi fields rule
$patron = Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron->new();

$patron->{firstname} = 'Julian';
$patron->{surname} = 'Maurice';

$patron->{import}{config}{exclusions} = [
    {
        'origin' => 'ext',
        'fields' => {
            'surname' => 'Maurice',
            'firstname' => 'Matthias'
        }
    }
];

is($patron->to_skip(), 0, 'Patron Julian must not be skipped');

$patron->{firstname} = 'Matthias';

is($patron->to_skip(), 1, 'Patron Matthias must be skipped');

done_testing();