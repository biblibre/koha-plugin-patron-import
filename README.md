# Koha's patron import plugin

This plugin is intended to create and configure regular patron imports

## Cronjob

Cronjob should be executed daily, preferably at night to prevent 
interfere with Koha's normal use.

Example:

```
PERL5LIB=/path/to/koha
KOHA_CONF=/path/to/koha-conf.xml
PATH_TO_PLUGIN=/path/to/plugin

0 23 * * * perl $PATH_TO_PLUGIN/Koha/Plugin/Com/Biblibre/PatronImport/cron/run-import.pl -i 1 -f /path/to/patrons.csv
```
## Configuration

You can access the plugin's configuration in the Koha's plugins home page.
- find the **Patron import** plugin in the table
- click on *Action -> configure*

Here you can add a new **import** and see existing ones.

#### Create a new import

Click on *New import* and fill the form as you need
- The *Import name* can be what you want
- There is 2 options in *Flow type* but only *CSV file* is currently usable
- All other form element are described

#### Configure an import

 Once you created a new import, you can see it in the home configuration page.
 Each blue fieldset represent an import and can be configured:
 - **mappings** *Set field and value mappings, apply transformation plugins and add a matching point
 - **Protected/erasables** *Define which fields must be protected or erasables
 - **Default values** *Add default values for some fields*
 - **Exclusion** *Create exclusion rules based on incoming data or Koha's account*
 - **Deletion** *Create deletion rules based on incoming data. Be careful with this
 - **Debarments** *You can automatically suspend the new created patron for a defined period
 - **Edit** and **Delete** *Edit your import main settings and delete it*
