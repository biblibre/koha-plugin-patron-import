# Field mappings

Field mapping consists of moving the content of incoming data field into the koha patron field.
Basically, it means that we will tells Patron-import: *put the content of the incoming field "Name" into the Koha patron field "surname"*.

### Accessing mappings page
Once you [created your import](import.md), you can see it in the plugin configuration home page. In here, click on "mappings" link.

### Add new field mapping
To add a field mapping, enter a field name in the left side od the table (column Source field), that should correspond to an existing field in your source data, and select the koha field to map with. Click on add button.

![Field mapping](img/field-mapping.jpg)
	
### Implicit mappings

If your source field's name match a koha field name, you do not have to explicitly create the mapping. The plugin will implicitly made it.
I.e surname => surname is not necessary except if you have to apply [value mappings](value-mappings.md) or [transformation plugins](transformation-plugins.md).

### Tokens

You can use tokens in source field column. Tokens are source fields name surrounded by angle bracket. They are used for conditional mappings or conactenation.

![Concatenation](img/concat_token.jpg)
> In the screenshot above, sources fields num and street will be concatenated with ', ' as separator and mapped in the address koha field.

![Conditional mapping](img/conditional_token.jpg)
> In the screenshot above, email will be mapped if it is not empty. If it is, id will be.
