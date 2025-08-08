.. _create_import:

Create new import
=================

Once the plugin has been installed, you can access its configuration from the Koha plugins home page.

Find the Patron import plugin in the table and click on ``Action->configure``.
Here you can add one or more imports and view existing imports. Click on `"New import"` and fill in the form as required.

The Import name can be anything you like. There are 2 options for the type of feed: CSV or LDAP server.
All other form elements are described.

To create new import, click on the `"New import"` plugin configuration page and complete the form:

- **Import name**: Name of your import. Can be anything you like.
- **Flow type**: Type of data source. This can be a CSV or LDAP server.
- **Create only**: If this box is checked, only a new user is added. No update.
- **Auto Cardnumber**: Let the plugin create cardnumber for your patrons.
- **Send email to new patrons**: In the same way as Koha's embedded functionality for CSV imports, send an email based on the “WELCOME” template
- **Clear reports and logs older than**: Number of days for which import reports are stored in the database. They are then deleted.

CSV Settings
------------

- **CSV path**: Path of CSV file to be imported. If it is empty, you must specify it as a parameter of the import script.
- **Binary**: CSV option, see https://metacpan.org/pod/Text::CSV#binary
- **End of line**: CSV option, see https://metacpan.org/pod/Text::CSV#eol
- **Char separator**: CSV option, see https://metacpan.org/pod/Text::CSV#sep_char
- **Quote char**: CSV option, see https://metacpan.org/pod/Text::CSV#quote_char
- **Allow loose quotes**: CSV option, see https://metacpan.org/pod/Text::CSV#allow_loose_quotes

Configuration handler
----------------------

You can export your configuration by clicking on the `"Export this configuration"` link.
When you click on it, an entry appears, allowing you to choose the name of your `YAML` file.

You can also apply a configuration from a `YAML` (well-structured) file. 
On an existing import profile or directly with a new one.

.. figure:: img/config-handler.png
   :alt: Configuration Handler

   Configuration handler