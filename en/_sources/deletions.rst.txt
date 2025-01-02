.. _deletions:

Deletions
=========

Deletion rules are a set of fields/values defining which patrons are to be deleted in Koha.

Several conditions must be met to delete a patron: 

#. Entire rule fields must have been matched the incoming data
#. Incoming data must have been associated with a corresponding patron in Koha with regard to the `matching point`
#. Koha's target patron must not have any due charges
#. Koha's target patron must not have any due checkouts

Create a rule
-------------

Type a rule name and click `"Add"` button.

.. figure:: img/add-deletion-rule.jpg
   :alt: Add rule

   Add rule

Add fields
----------

Select a field, entrer a value and click on the `"Add"` button.

.. figure:: img/add-deletion-field.jpg
   :alt: Add field
