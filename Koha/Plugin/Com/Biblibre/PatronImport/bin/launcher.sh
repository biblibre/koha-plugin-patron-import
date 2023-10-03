#!/bin/bash

# This scripts launch the imports of the plugin.
#   Replace all the value between <> by the correct one.
#   Pay attention to the following variables:
#     - PERL5LIB: specially the part that point on the plugin path
#     - PI_PATH is the path of the patron-import plugin
#     - TODAY: is used to match today's file name and/or rename them in archives directory
#
# Importing
#   Set IMPORT_DIR which is the path where files are uploaded.
#   Set FILE which is the filemane to import. You can use TODAY inside this name.
#   Set FILE2 if needed.
#   Add a FILEx and copy paste the file section if needed
#
# Archiving files
#   Set variable ARCHIVES_DAYS with a number greater than 0 to enable archiving
#   and set ARCHIVES_DIR.
#     - ARCHIVES_DAYS: number of days we keep imported files (archives)
#     - ARCHIVES_DIR: path where the imported files are archived
# Logging
#   Logging allows to redirect launcher output in some files.
#   Set LOG_DIR to enable logging. Else output is redirected to /dev/null
  
export KOHA_CONF=/home/koha/etc/koha-conf.xml
export PERL5LIB=/home/koha/src:/home/koha/src/lib:/home/koha/lib/koha-plugin-patron-import/;
PI_PATH=/home/koha/lib/koha-plugin-patron-import/Koha/Plugin/Com/Biblibre/PatronImport

TODAY=$(date "+%Y-%m-%d")

# Importing
IMPORT_DIR=/home/koha/webdatas/private/patrons
FILE=$IMPORT_DIR/<students>.csv
FILE2=$IMPORT_DIR/<staff>.csv

# Archiving
ARCHIVES_DAYS=0;
ARCHIVES_DIR=/home/koha/patrons/archives

# Logging
LOG_DIR=/home/koha/patrons/archives/logs

if [ ! -d "$LOG_DIR" ]; then
    echo "Creating directory structure: $LOG_DIR"
    mkdir -p "$LOG_DIR"
fi

if [ -f "$FILE" ]; then
    echo "Import file $FILE"
    if [ -n "$LOG_DIR" ]; then
        perl "$PI_PATH/cron/run-import.pl" -f "$FILE" -i <import-id> >> "$LOG_DIR/<student>_$TODAY.log" 2>&1
    else
        perl "$PI_PATH/cron/run-import.pl" -f "$FILE" -i <import-id> >> /dev/null 2>&1
    fi

    if (( ARCHIVES_DAYS > 0 )); then
        mv "$FILE" "$ARCHIVES_DIR/students_$TODAY.csv"
    fi
fi

if [ -f "$FILE2" ]; then
    echo "Import file $FILE2"
    if [ -n "$LOG_DIR" ]; then
        perl "$PI_PATH/cron/run-import.pl" -f "$FILE2" -i <import-id> >> "$LOG_DIR/<staff>_$TODAY.log" 2>&1
    else
        perl "$PI_PATH/cron/run-import.pl" -f "$FILE2" -i <import-id> >> /dev/null 2>&1
    fi

    if (( ARCHIVES_DAYS > 0 )); then
        mv "$FILE2" "$ARCHIVES_DIR/<staff>_$TODAY.csv"
    fi
fi

# Purge
if (( ARCHIVES_DAYS > 0 )); then
<<<<<<< HEAD
    find "$ARCHIVES_DIR" -maxdepth 1 -mtime "+$ARCHIVES_DAYS" -name '*.csv' -delete
=======
    find $ARCHIVES_DIR -maxdepth 1 -mtime +$ARCHIVES_DAYS -name '*.csv' -delete
>>>>>>> add-array-format-xattr
fi
