.. _add-ons:

Add-ons
=======

A patron-import add-on is simply a Koha plugin that implements one or more hooks called by the main plugin (patron-import).

A add-on is used to handle specific cases that are not feasible by
configuring the plugin like complex mappings or unusual data
transformation.

Create an add-on
----------------

First, create the plugin’s directory. It should respect this structure:
my-plugin-name/Koha/Plugin/Com/Biblibre/MyPluginName.pm.

A good practice is to name the plugin base directory like `"koha-plugin-myplugin-patron-import"`.

``koha-plugin-myplugin-patron-import/Koha/Plugin/Com/Biblibre/MyPlugin.pm``

Create this directory on a place where Koha can access / read.

Your plugin must contain at least this code to be installed
by the Koha plugin system: Here is a starter for a plugin named
“Example”:

.. code:: perl

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

Hooks
~~~~~

A hook is called multiple times during the import process. Each hook
corresponds to a specific point in the import. See `“Available hooks”` section below to learn when they are called and how to implement them.

To implement a hook add it where you want in the add-on package:

.. code:: perl

   sub patron_import_mapping_preprocess {
       my ($self, $data, $borrower) = @_;

       # your specific code here.
   }

**Available hooks:**

.. tip::
    For authorized users, you can check the `Example
    add-on <https://git.biblibre.com/Add-on-patron-import/koha-plugin-example-patron-import/src/branch/master/Koha/Plugin/Com/Biblibre/Example.pm>`__.

Here is a list of available hooks and how they should be written.

- **patron_import_mapping_postprocess**

| This hook is called just after the field and value mappings are
  processed.
| ``$borrower`` is the futur Koha patron.

.. code:: perl

   sub patron_import_mapping_postprocess {
       my ($self, $borrower) = @_;
   }

- **patron_import_patron_update**

| Called before the patron is updated in Koha.
| ``$patron`` is the incoming patron
| ``$extended_attributes`` contains the incoming patron extended attributes
| ``$stored_patron`` is the current Koha patron
| ``$stored_extended_attributes`` contains the current patron extended attributes

.. code:: perl

   sub patron_import_patron_update {
       my ($self, $patron, $extended_attributes, $stored_patron, $stored_extended_attributes) = @_;
   }

- **patron_import_patron_updated**

| Called after the patron is updated in Koha.
| ``$borrowernumber`` is the updated borrowernumber.

.. code:: perl

   sub patron_import_patron_updated {
       my ($self, $borrowernumber) = @_;
   }

- **patron_import_patron_create**

| Called before the patron is created in Koha.
| ``$patron`` is the incoming patron
| ``$extended_attributes`` contains the incoming patron extended attributes

.. code:: perl

   sub patron_import_patron_create {
       my ($self, $patron, $extended_attributes) = @_;
   }

- **patron_import_patron_created**

| Called after the patron is created in Koha.
| ``$borrowernumber`` is the updated borrowernumber.

.. code:: perl

   sub patron_import_patron_created {
       my ($self, $borrowernumber) = @_;
   }

- **patron_import_to_skip**

| Called to define if the patron should be ignored by the import process.
| ``$patron`` id the mapped incoming patron.

.. code:: perl

   sub patron_import_to_skip {
       my ($self, $patron) = @_;
   }

- **patron_import_patron_exists**

| Called to define an additionnal condition after matchingpoint result.
| ``$patron`` is the mapped incoming patron. ``$borrowernumber`` is the
  borrowernumber found (or not) by matchingpoint

.. code:: perl

   sub patron_import_patron_exists {
       my ($self, $patron, $borrowernumber) = @_;
   }

Now you created your add-on, you will have to install it.

Installation
------------

| Installing steps:

   #. Clone or upload your add-on on the server
   #. Add it in the Koha configuration file
   #. Launch the plugin installer
   #. Enable the add-on 
   #. Link the add-on to a configured import

Clone or upload your add-on on the server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Place your add-ons directory somewhere Koha can access it

.. code:: bash

   koha@koha:~$ cd /home/koha/lib/
   koha@koha:~$ git clone https://git.biblibre.com/Add-on-patron-import/koha-plugin-example-patron-import.git

Add it in the Koha configuration file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Edit your koha-conf.xml and add a ``<pluginsdir>`` tag inside the
``<config>`` one.

.. code:: xml

   <config>
     <pluginsdir>/home/koha/lib/koha-plugin-example-patron-import</pluginsdir>

..

At this point you might need to restart some Koha services and clear cache.

Launch the plugin installer
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Go the Koha source code and run this command:

.. code:: bash

   koha@koha:~$ /home/koha/src/
   koha@koha:~$ perl misc/devel/install_plugins.pl

You should see this when your plugin is successfully installed:

.. code:: bash

   Installed Example Add-on for Patron Import plugin version 1.0
   All plugins successfully re-initialised

Enable the add-on
~~~~~~~~~~~~~~~~~

| Before being used by Koha or other plugins the add-on must be enabled.
| Go to the Koha plugins home page (`cgi-bin/koha/plugins/plugins-home.pl`), find your add-on, click on ``Actions`` and the ``Enable`` button.

Link the add-on to a configured import
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

| Once your add-on is installed and enabled, you should see it when editing an import configuration.
| Here appear all the enabled plugins that implement at least one patron-import hook.
| Just select the add-on(s) you want be used with the import.

