Introduction
============

This plugin allows you to import patrons from a CSV file or by a LDAP server.
Several mappings are available to define how to import the data.

The creation of add-ons is possible in order to extend the capabilities of the plugin during the import process.

Before starting
---------------

Before configuring the plugin, here are the basic (and **important**) elements that you need to prepare.

From which source ?
~~~~~~~~~~~~~~~~~~~

CSV or LDAP

Ideally the csv should be encoded in utf8. The first line of the CSV must be the **column headers**.

For a LDAP import, this additional informations are needed:

- **host and port** of the LDAP to be requested (IP address or URL)
- an authorized **account** (distinguished name) and **password** to read the directory if the anonymous bind is not allowed
- a **search base** that is kind a sub-directory where the accounts to import are
- a **search filter** which allow the LDAP search to select only the wanted entries (optional)

Field mappings
~~~~~~~~~~~~~~

Create a mapping table between source fields and Koha fields.

+-------------------+----------------+
| Source field      | Koha field     |
+===================+================+
| name              | surname        |
+-------------------+----------------+
| type              | categorycode   |
+-------------------+----------------+
| mail              | email          |
+-------------------+----------------+

If a source field is named the same way than the corresponding Koha field, the mapping is implicit and does not need to be defined in the configuration page.
Unless the field value must correspond to a certain value or be transformed.

Value mappings
~~~~~~~~~~~~~~

Define the values that need to be transformed before being imported into Koha, and provide a transformation table for each field that requires it.
Particularly for values that must correspond to an authorized value in Koha (e.g. categorycode, branchcode).

The transformation process allows regular expressions such as “strict equals”, “starts with”, “contains”.
For very specific treatments, an add-on must be drawn up.

Matching point
~~~~~~~~~~~~~~

One or more fields to be used for deduplicate patrons.
It is preferable to use unique fields (userid, cardnumber). Extended attributes can be used.

Default values (optional but recommended)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Set default for certain fields if they are empty (or invalid for categorycode and branchcode).
The definition of default values for **categorycode and branchcode** should be systematic.

Automating
~~~~~~~~~~

Automation involves adding the import to a :ref:`cronjob <tools>`. This requires some important information:

- **frequency** (each hour/day/week/month ?)
- **time** important to avoid processing during hours of use/opening
- **where** the CSV file will be uploaded on the server (not for LDAP)
- **naming** of CSV file may contain a date part which will be replaced by the current date during import 

.. note:: 
    Pay attention to the import time. A file could be uploaded at 11:50 pm and imported at 00:30 am the day after.

.. toctree::
   :maxdepth: 2
   :caption: Contents

   create_import
   define_mappings
   protected_erasables_fields
   default_values
   exclusions
   deletions
   debarments
   extented_attributes
   logs
   tools
   add-ons