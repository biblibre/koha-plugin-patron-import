.. _tools:

Tools
=====

Cronjob
-------

Cronjob should be run daily, preferably at night to avoid interfering with normal use of Koha.

*Example:*

.. code:: bash

   PERL5LIB=/path/to/koha
   KOHA_CONF=/path/to/koha-conf.xml
   PATH_TO_PLUGIN=/path/to/plugin

   0 23 * * * perl $PATH_TO_PLUGIN/Koha/Plugin/Com/Biblibre/PatronImport/cron/run-import.pl -i 1 -f /path/to/patrons.csv

Launcher
--------

A launcher is provided to help you to run import(s) automatically (e.g. crontab). 

Available in ``$PATH_TO_PLUGIN/Koha/Plugin/Com/Biblibre/PatronImport/bin/launcher.sh``