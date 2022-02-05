#!/bin/bash

# Dump all tables related to this plugin

plugin_tables=$(mysql -N -s -e 'SHOW TABLES'\
 | grep '^koha_plugin_com_biblibre_patronimport_'\
 | paste -s -d ' ')

if [[ ! $plugin_tables ]]
then
    echo "ERROR : No tables starting with 'koha_plugin_com_biblibre_patronimport_'"
    exit 1
fi

dbname=$(grep -s 'database=' ~/.my.cnf | awk -F '=' '{print $2}')
if [[ ! $dbname ]]
then
    echo "ERROR : Impossible to find database name in ~/.my.cnf"
    exit 2
fi

mysqldump $dbname $plugin_tables
