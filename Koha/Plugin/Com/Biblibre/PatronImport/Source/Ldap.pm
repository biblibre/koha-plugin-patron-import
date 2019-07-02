package Koha::Plugin::Com::Biblibre::PatronImport::Source::Ldap;

use Modern::Perl;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Mapping;
use YAML;
use Net::LDAP;
use Data::Dumper;

sub in {
    my $class = shift;
    my $args = shift;

    my $conf = get_conf;

    my $this = bless( {index => 0, entries => ''}, $class );

    # Connect to ldap servetr and load ldap entries.
    my $ldap_conf = $conf->{setup}->{ldap};
    $ldap_conf->{ldaphost} = $args->{from};

    my $ldap = $this->ldap_bind($ldap_conf);

    if ($ldap_conf->{search}->{filter_params}) {
        foreach my $param (keys %{ $ldap_conf->{search}->{filter_params} }) {
            my $code = $ldap_conf->{search}->{filter_params}->{$param};
            my $value = eval $code;
            if ($@) {
                warn "Error while processing $param: $@";
                warn "Code processed: ";
                warn $code;
                next;
            }
            $ldap_conf->{search}->{filter} =~ s/\Q$param\E/$value/g;
        }
    }

    my $mesg = $ldap->search(%{ $ldap_conf->{search} });

    if ($mesg->{resultCode}) {
        warn "LDAP search failed with status $mesg->{resultCode} - $mesg->{errorMessage}";
        warn Data::Dumper::Dumper $mesg;
    }

    # Set ldap specifics properties for ths object.
    $this->{entries} = $mesg,

    return $this;
}

sub next {
    my $this = shift;
    my $entry = $this->{entries}->entry($this->{index}) or return;
    my $patron = $this->unbless_entry($entry);
    $this->{index}++;
    return process_mapping($patron);
}

sub ldap_bind {
    my ($this, $ldap_conf) = @_;
    my $ldap = Net::LDAP->new($ldap_conf->{ldaphost}) or die "$@";
    if ($ldap_conf->{anonymous_bind}) {
        $ldap->bind;
    } else {
        $ldap->bind( $ldap_conf->{ldap_user}, password => $ldap_conf->{ldap_pass}) or die "$@";
    }

    return $ldap;
}


sub unbless_entry {
    my ($this, $entry) = @_;

    my $data;
    my @attributes = $entry->attributes();
    foreach my $attribute (@attributes) {
        my $value = $entry->get_value($attribute);
        $data->{$attribute} = $value || '';
    }

    return $data;
}

1;
