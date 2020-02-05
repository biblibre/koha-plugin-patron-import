package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins;

use Modern::Perl;

our $plugins = {
    uc_first => {
        code => 'uc_first',
        name => 'UC first',
        description => 'Upper case first value letter',
        package => 'Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::UCFirst'
    },
    uc_all => {
        code => 'uc_all',
        name => 'Upper case',
        description => 'Upper case all value letters.',
        package => 'Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::UCAll'
    },
    lc_first => {
        code => 'lc_first',
        name => 'LC first',
        description => 'Lower case first value letter.',
        package => 'Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::LCFirst'
    },
    lc_all => {
        code => 'lc_all',
        name => 'Lower case',
        description => 'Lower case all value letters.',
        package => 'Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::LCAll'
    },
    left_trim => {
        code => 'left_trim',
        name => 'Left trim',
        description => 'Removes extra spaces from leftmost side of the string till the actual text starts. From the leftmost side the string takes 1 or more white spaces (\s+) and replaces it with nothing.',
        package => 'Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::LeftTrim'
    },
    right_trim => {
        code => 'right_trim',
        name => 'Right trim',
        description => 'Removes extra spaces from rightmost side of the string till the actual text end is reached. From the rightmost side the string takes 1 or more white spaces (\s+) and replaces it with nothing.',
        package => 'Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::RightTrim'
    },
};

sub all {
    my $all = [];

    while ( my ($name, $plugin) = each (%$plugins)) {
        push @$all, $plugin;
    }

    return $all;
}

sub get {
    my ($name) = @_;

    if ( defined( $plugins->{ $name } ) ) {
        return $plugins->{ $name };
    }

    return '';
}

1;
