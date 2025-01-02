.. _define_mappings:

Define mappings
================

Mapping definitions is a very important feature of this plugin, as it determines how the data will be interpreted.

When you :ref:`created an import <create_import>`, you choose a *flow type* which is the source type of your data.
Whichever type of source you import from, Patron-import will transform the source data into tabular data.
This tabular data is referred to here as **incoming data**. Mappings are applied to the incoming data to create a Koha patron.

This data transformation involves several optional steps:

Fields mappings
---------------

Field mapping consists in moving the incoming data field into the koha patron field.
Basically, this means that we will tell Pattern-import: "move the incoming data to the Koha field related to the patron".

Accessing mappings page
~~~~~~~~~~~~~~~~~~~~~~~

Once you've :ref:`created an import <create_import>`, you can view it on the plugin configuration home page. On this page, click on the “mappings” link.

Add new field mapping
~~~~~~~~~~~~~~~~~~~~~

To add a field match, enter the name of a field in the left-hand part of the table (Source field column).
Which must match an existing field in your source data, and select the koha field to match. Click on `add` button.

.. figure:: img/field-mapping.jpg
   :alt: Field mapping

   Field mapping

Implicit mappings
~~~~~~~~~~~~~~~~~

If the name of your source field matches the name of a koha field, you don't need to explicitly create the match.
The plugin will do this implicitly. For example, ``surname => surname`` is not required except if you have to apply value mapping or transformation plugin.

Tokens
~~~~~~

You can use tokens in the source field column. Tokens are source field names surrounded by square brackets. They are used for conditional matches or concatenation.

.. figure:: img/concat_token.jpg
  :alt: Concatenation with comma

  'num' and 'street' will be concatenated with ‘,’ as separator and mapped in the address koha field.

.. figure:: img/conditional_token.jpg
  :alt: Concatenation with pipe
  
  Email will be mapped if it is not empty. If it is, id will be.

Value mappings
--------------

Value mappings allow you to transform source field values into other values during the mapping process.
Value matches are configured for each field mapping.

Add new value mapping
~~~~~~~~~~~~~~~~~~~~~

In the field mapping page, click on `value mappings` button of the corresponding field mapping.
In the table, add as any value mappings as you like and save.

The value on the left (input value) is the incoming value of your source field.
The value on the right (output value) is the replacement value.

A good example for value mappings is the transformation of category codes to match valid koha categorycodes.

.. figure:: img/value-mappings.jpg
   :alt: Value mappings

   Value mappings

In the example above, for the field mapping in destination to
categorycode, “Adult” will tranformed to “ADU”, “Young” to “YNG” and
“Librarian” to “LIB”

If none of this rules match
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Under the value mapping table you can define a “fallback” value.
This value will only be set if none of the existing rules match the field.
Not to be confused with the :ref:`default values <default_values>` which are applied if the field is empty or non-existent.

.. figure:: img/if-none-rules-match.jpg
   :alt: No rule match

   No rule match


Transformation plugins
----------------------

Tranformation plugins are a set of data filters available to apply frequent changes to incoming data.
They are applied just after the field mapping process and before the value mapping.

The mapping order is:

1. Field mapping (source field => target field) 
2. **Transformation plugins** 
3. Value mapping 
4. Default value

You can choose none, one or more transformation plugins.
To apply them, click on the `"Transformation plugins"` button in the corresponding mapping on the field mapping page.

In the transformation plugins page, select the ones you wish to use.

.. figure:: img/transformation-plugins.jpg
  :alt: Transformation plugins

  Transformation plugin

Matching point
--------------

When importing a patron, the import process needs to know whether it is a new Koha patron (create) or an existing one (update) in Koha that needs to be modified.

To determine that, we have to create a matching point.
A matching point is one or more field(s) that will be searched in Koha patron database.
If it corresponds to a Koha patron, it will be updated with the incoming data, otherwise a new patron will be created.

.. note::
  Note that all fields in the match point are requested using an “AND” operator. Not “OR”. 
  This means that all fields must match, not just one.

Add a field to the matching point by selecting it from the list below the field mapping table and clicking on `"add"`.