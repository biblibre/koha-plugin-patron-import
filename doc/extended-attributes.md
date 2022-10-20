# Extended attributes

This page is intended to configure the behavior for each existing patron's extended attributes when updating Koha's borrower.

The starting point is that some patron's attributes should already have one or more values inside and
the plugin needs explicitly to know if it erase, add a new value, or do nothing and that for repeatable **AND** not repeatable attributes.

For each attribute, the behavior is configurable in 2 different situations:
1) the existing patron's attribute is already set with one value (only one)
2) the existing patron's attribute is already set with more than one value (many)

In the 3rd possible situation (the attribute has no value) the behavior is allways the same: add the value.

![Extended attributes](img/extended-attributes.jpg)

**Why configuring the behavior for a non repeatable attribute ?**
This is because, even if it is not possible via the Koha staff interface, programmatically we can add more than one value on a non-repeatable attribute.
Also it was noticed that some libraries use non-repeatable attributes as multi-valued. If we programmatically (or with a SQL query) add 2 values to
a non repeatable attribute, these 2 values are shown in the patron detail page.
So we make possible to not erase non-repeatbale attributes (and so add values) to avoid losing their data.

### Extended attributes behavior

* **Update existing**: erase the existing value. Avalaible only in the case it already have only one value,
* **Always add**: will always add the value to the attribute,
* **Add if the value does not exists**: check if the incoming match an existing value. If yes do nothing. Else add a new one,
* **Do nothing**: Nothing is added or updated,

> Note that the 2nd situation (attribute alerady have many values) is not configurable for non-repeatable attributes.
> In this case the plugin do nothing.
