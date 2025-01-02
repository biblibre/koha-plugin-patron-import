.. _exclusions:

Exclusions
==========

Exclusion rules can be used to define certain incoming patrons to be ignored.

A rule is a set of ``koha field => value``. All rule fields must match for the patron to be ignored.

There is two rule types:

- **External**: match incoming data 
- **Koha**: match Koha data (if a matching patron has been found).

Create a rule
-------------

Enter a rule name, check whether you want a Koha rule or not and click on the `“Add”` button.

.. figure:: img/add-exclusion-rule.jpg
   :alt: Add rule

   Add rule

Add fields
----------

Select a field, entrer a value and click on `“Add”` button.

.. figure:: img/add-exclusion-field.jpg
   :alt: Add field

   Add field