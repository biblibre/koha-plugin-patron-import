package Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    GetFromTable
    GetFirstFromTable
    InsertInTable
    UpdateInTable
    Delete
    Count
);

use Modern::Perl;
use C4::Context;

sub GetFromTable {
    my ($table, $params, $additional) = @_;

    my $dbh = C4::Context->dbh;

    my $query = "SELECT * FROM $table" . _buildQuery($params);
    $query .= $additional || '';
    my $sth = $dbh->prepare($query);
    $sth->execute(_buildParams($params)) or die $sth->errstr;
    my $data = $sth->fetchall_arrayref({});

    return $data;
}

sub GetFirstFromTable {
    my $result = GetFromTable(@_);

    return $result ? $result->[0]: ();
}

sub InsertInTable {
    my ($table, $values) = @_;

    my $dbh = C4::Context->dbh;

    my $query = "INSERT INTO $table (";
    $query .= join(', ', map { $_ } keys %$values) .")";
    $query .= " VALUES (" . join(', ', map { '?' } keys %$values) . ")";
    my $sth = $dbh->prepare($query);
    $sth->execute(_buildParams($values)) or die $sth->errstr;

    return $sth->{mysql_insertid};
}

sub UpdateInTable {
    my ($table, $values, $params) = @_;

    my $dbh = C4::Context->dbh;

    my $query = "UPDATE $table";
    $query .= " SET " . join(', ', map { "$_= '$values->{$_}'" } keys %$values);
    $query .= " WHERE " . join(' AND ', map { "$_ = \"$params->{$_}\"" } keys %$params);

    $dbh->do($query) or die $dbh->errstr;;
}

sub Delete {
    my ($table, $params) = @_;

    my $dbh = C4::Context->dbh;

    my $query = "DELETE from $table" . _buildQuery($params);
    my $sth = $dbh->prepare($query);
    my $r = $sth->execute(_buildParams($params)) or die $sth->errstr;
}

sub Count {
    my ($table, $params, $additional) = @_;

    my $dbh = C4::Context->dbh;

    my $query = "SELECT * FROM $table" . _buildQuery($params);
    $query .= $additional;
    my $sth = $dbh->prepare($query);
    $sth->execute(_buildParams($params)) or die $sth->errstr;

    return $sth->rows;
}

sub _buildValues {
    my ($params) = @_;

    return unless $params;

    return join(', ', map { "$_= '$params->{$_}'" } keys %$params);
}

sub _buildQuery {
    my ($params) = @_;

    return '' unless $params;

    return ' WHERE ' . join(' AND ', map { "$_ = ?" } keys %$params);
}

sub _buildParams {
    my ($params) = @_;

    return map { $params->{$_} } keys %$params;
}

sub AuthorisedValues {
    my ($category) = @_;

    my $foo = GetFromTable('authorised_values',
        {category => $category});

    $foo;
}

sub AuthorisedValue {
    my ($category, $value) = @_;

    return GetFirstFromTable('authorised_values',
        {category => $category, authorised_value => $value});
}

1;
