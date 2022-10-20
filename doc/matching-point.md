# Matching point

When importing a borrower from external source, the import process needs to know if it a new Koha patron (create) or if there is an existing one (update) in Koha to be modified.

To determine that, we have to create a matching point. A matching point is one or more field(s) that will be searched in Koha patron database. If they match a Koha borrower, it will be updated with incoming data, else a new patron is created.

> Note that all the field of the matching point are requested with a "AND" operator. Not "OR".
> That means all the fields must match and not at least one. 

Add a field to the matching point by selecting one in the list under the [field mappings](field-mappings.md) table and click add.
