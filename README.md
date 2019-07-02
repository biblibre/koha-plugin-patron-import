# Koha's patron import plugin

This plugin is intended to create and configure regular patron imports

# Cronjob

Cronjob should be executed daily, preferably at night to prevent 
interfere with Koha's normal use.

Example:

```
PERL5LIB=/path/to/koha
KOHA_CONF=/path/to/koha-conf.xml
PATH_TO_PLUGIN=/path/to/plugin

0 23 * * * $PATH_TO_PLUGIN/Koha/Plugin/Com/BibLibre/PatronImport/cron/run_import.pl -i 1 -f /path/to/patrons.csv
```
