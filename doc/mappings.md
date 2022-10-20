# Define mappings

Defining mappings is the basis of importing patrons from external sources.
When you [created your import](import.md), you chose a *flow type* which is the source type of your data.
Whatever the source type you are importing from, Patron-import will tranform the source data to tabular data. These tabular data are called here **incoming** data. Mappings apply to incoming data in order to create à Koha patron.

This data transformation has different optional steps:
- [Field mappings](field-mappings.md)
- [Value mappings](value-mappings.md)
- [Transformation plugins](https://github.com/biblibre/koha-plugin-patron-import/wiki/Transformation-plugins)
- Matching points
