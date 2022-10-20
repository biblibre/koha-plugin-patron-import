# Add-ons patron-import

An add-on for patron-import is simply a Koha plugin that implement a or more hooks called by the main plugin (patron-import).

A add-on is used to handle specific cases that are not feasible by configuring the plugin like complex mappings or unusual data transformation.

#### Create the plugin's directory and package

First, create the plugin's directory. It should respect this structure: my-plugin-name/Koha/Plugin/Com/Biblibre/MyPluginName.pm.

> A good practice is to name the plugin base directory like koha-plugin-myplugin-patron-import.

`koha-plugin-myplugin-patron-import/Koha/Plugin/Com/Biblibre/MyPlugin.pm`

Create this directory on a place where Koha can access / read.

#### Code base for an add-on

Your plugin should contain at least this code in order to be installed by the Koha plugin system:
Here is a starter for a plugin named "Example":

```perl
package Koha::Plugin::Com::Biblibre::Example;

use base qw(Koha::Plugins::Base);

our $VERSION = '1.0';

our $metadata = {
    name            => 'Example Add-on for Patron Import plugin',
    author          => 'Joe Bar <joe.bar@foo.com>',
    description     => 'Example Add-on for Patron Import plugin',
    date_authored   => '2022-10-30',
    date_updated    => '2020-10-30',
    minimum_version => '21.11',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

1;
```

#### Implement hooks

A hook is called at several times during the import process. Each hook correspond to a specific moment during the import. See the under secton "Available hooks" to see when they are called and how implent them.

To implement a hook add it where you want in the add-on package:

```perl
sub patron_import_mapping_preprocess {
    my ($self, $data, $borrower) = @_;

    # your specific code here.
}
```

#### Available hooks

For authorized users, you can check the [Example add-on](https://git.biblibre.com/Add-on-patron-import/koha-plugin-example-patron-import/src/branch/master/Koha/Plugin/Com/Biblibre/Example.pm).

Here is a list of available hooks and the way they should by wrote.


##### patron_import_mapping_postprocess

This hook is called just after the field and value mappings are processed.  
`$borrower` is the futur Koha patron.  

```perl
sub patron_import_mapping_postprocess {
    my ($self, $borrower) = @_;
}
```

##### patron_import_patron_update

Called before the patron is updated in Koha.  
`$patron` is the incoming patron  
`$extended_attributes` contains the incoming patron extended attributes  
`$stored_patron` is the current Koha patron  
`$stored_extended_attributes` contains the current patron extended attributes  

```perl
sub patron_import_patron_update {
    my ($self, $patron, $extended_attributes, $stored_patron, $stored_extended_attributes) = @_;
}
```

##### patron_import_patron_updated

Called after the patron is updated in Koha.  
`$borrowernumber` is the updated borrowernumber.  

```perl
sub patron_import_patron_updated {
    my ($self, $borrowernumber) = @_;
}
```

##### patron_import_patron_create

Called before the patron is created in Koha.  
`$patron` is the incoming patron  
`$extended_attributes` contains the incoming patron extended attributes  

```perl
sub patron_import_patron_create {
    my ($self, $patron, $extended_attributes) = @_;
}
```

##### patron_import_patron_created

Called after the patron is created in Koha.  
`$borrowernumber` is the updated borrowernumber.  

```perl
sub patron_import_patron_created {
    my ($self, $borrowernumber) = @_;
}
```

##### patron_import_to_skip

Called to define if the patron should be ignored by the import process.  
`$patron` id the mapped incoming patron.  

```perl
sub patron_import_to_skip {
    my ($self, $patron) = @_;
}
```

Now you created your add-on, you will have to install it. See the [Install / use add-on](install-add-on.md) page.
