# Koha's patron import plugin

This plugin is intened to create and configure regular patron imports

# Cronjob

Le cronjob doit être lancé quotidiennement, de préférence la nuit
pour ne pas gêner l'utilisation normale de Koha.

Exemple:

```
PERL5LIB=/path/to/koha
KOHA_CONF=/path/to/koha-conf.xml
PATH_TO_PLUGIN=/path/to/plugin

0 23 * * * $PATH_TO_PLUGIN/Koha/Plugin/Com/BibLibre/PatronImport/cron/run_import.pl -i 1 -f /path/to/patrons.csv
```
