# Patron-import Koha plugin

Patron-import is a plugin for [Koha](https://koha-community.org/) allowing configurable, customizable and automated patrons import.

### Current versions
- 18.05-1.x => Koha 18.05.xx, 18.11.xx and 19.05.xx
- 19.11-1.x => Koha 19.11.xx
- 20.05-1.x => Koha 20.05.xx
- 20.11-1.x => Koha >= 20.11.xx
- 21.05-1.x => Koha >= 21.05.xx
- **21.11-1.x => Koha >= 21.11.xx**
- master => Koha latest version

This documentation is for **21.11.xx** version

### Downloading
From the [release page](https://github.com/biblibre/koha-plugin-patron-import/releases), download the relevant .kpz file

### Getting started 

#### Before (project management)

Start importing patrons in a Koha system needs advance preparation.
All the things you need to draft is explain is the [before starting](before-starting.md) page.

#### Setup

Once the plugin is installed, you can access the plugin's configuration in the Koha's plugins home page.
- find the **Patron import** plugin in the table
- click on *Action -> configure*

Here you can add one or more **imports** and see existing ones.
Click on *New import* and fill the form as you need
- The *Import name* can be what you want
- There is 2 options in *Flow type* but only *CSV file* is currently usable
- All other form element are described

### Configuration
- [Create new import](import.md)
- [Define mappings](mappings.md)
    - [Field mappings](field-mappings.md)
    - [Value mappings](value-mappings.md)
    - [Transformation plugins](transformation-plugins.md)
    - [Matching points](matching-point.md)
- [Protected and erasables fields](protected-erasable.md)
- [Default values](default-values.md)
- [Exclusions](exclusions.md)
- [Deletions](deletions.md)
- [Debarments](debarments.md)
- [Extended attributes](extended-attributes.md)

### Plugins (add-ons)
- [Create an add-on](create-add-on.md)
- [Install / use add-on](install-add-on.md)
