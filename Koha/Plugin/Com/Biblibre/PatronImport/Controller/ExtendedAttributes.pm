package Koha::Plugin::Com::Biblibre::PatronImport::Controller::ExtendedAttributes;

use Modern::Perl;

use Koha::Patron::Attribute::Types;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons qw( PatronFields );

sub edit {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $import_id = $cgi->param('import_id');
    my $op = $cgi->param('op') || '';

    my $template = $plugin->get_template({ file => 'templates/extendedattributes/edit.tt' });

    my @attr_types = Koha::Patron::Attribute::Types->search->as_list;
    my $attr_types_unblessed;
    foreach my $attr_type ( @attr_types ) {
	push @{ $attr_types_unblessed }, $attr_type->unblessed;
    }

    if ( $op eq 'save' ) {
	Delete($plugin->{extended_attributes_table}, { import_id => $import_id });
	foreach my $attr_type ( @$attr_types_unblessed ) {
	    my $code = $attr_type->{code};
	    my $one_value = $cgi->param($code . '_one_value');
	    my $many_values = $cgi->param($code . '_many_values');

	    InsertInTable($plugin->{extended_attributes_table}, {
		import_id => $import_id,
		code => $code,
		behaviour_one_value => $one_value,
		behaviour_many_values => $many_values,
		repeatable => $attr_type->{repeatable}
	    });
	}
    }

    my $defaults = GetFromTable($plugin->{extended_attributes_table}, { import_id => $import_id});
    foreach my $default ( @$defaults ) {
	foreach my $attr_type ( @$attr_types_unblessed ) {
	    if ( $default->{code} eq $attr_type->{code} ) {
		$attr_type->{behaviour_one_value} = $default->{behaviour_one_value};
		$attr_type->{behaviour_many_values} = $default->{behaviour_many_values};
	    }
	}
    }

    $template->param(
        import_id => $import_id,
	attr_types => $attr_types_unblessed
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

1;
