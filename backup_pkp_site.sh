#!/bin/bash
# @name: backup_pkp_site.sh
# @creation_date: 2025-01-21
# @license: The MIT License <https://opensource.org/licenses/MIT>
# @author: Ronan Burnett
# @author: Simon Bowie <simonxix@simonxix.com>
# @purpose: back up a OJS / OMP database and website
# @acknowledgements:
# https://docs.pkp.sfu.ca/dev/upgrade-guide/en/
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts
# https://askubuntu.com/questions/1389904/read-from-env-file-and-set-as-bash-variables

############################################################
# variables                                                #
############################################################

# retrieve variables from .env file (see .env.template for template)
# source the .env file from the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

# Get today's date in ISO 8601 format
DATE=$(date -I)

PKP_BACKUP_PATH="$HOME/backups"
CONFIG_FILE="$PKP_WEB_PATH/config.inc.php"

############################################################
# subprograms                                              #
############################################################

function License()
{
  echo 'Copyright 2026 Simon Bowie <simonxix@simonxix.com>'
  echo
  echo 'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:'
  echo
  echo 'The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.'
  echo
  echo 'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
}

function Help()
{
   # Display Help
   echo "This script backs up an OJS or OMP database and website."
   echo
   echo "Syntax: backup_pkp_site.sh [-l|h|d|p|f|b]"
   echo "options:"
   echo "l     print the MIT License notification"
   echo "h     print this Help"
   echo "d     backup MySQL / MariaDB database"
   echo "p     backup PostgreSQL database"
   echo "f     backup website files"
   echo "b     full backup of database and files"
   echo
}

function MariaDB_backup()
{
  # Extract the values from the config.inc.php file
  USERNAME=$(grep '^username =' "$CONFIG_FILE" | awk -F' = ' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r\n')
  PASSWORD=$(grep '^password =' "$CONFIG_FILE" | awk -F' = ' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r\n')
  DBNAME=$(grep '^name =' "$CONFIG_FILE" | awk -F' = ' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r\n')

  # Check if all required fields are found
  if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$DBNAME" ]; then
    echo "Missing one or more required fields (username, password, name) in config.inc.php."
    exit 1
  fi

  # Create the dump filename
  DUMPFILE="$PKP_BACKUP_PATH/${DBNAME}_${DATE}.sql"

  # Perform the database dump
  mysqldump -u"$USERNAME" -p"$PASSWORD" "$DBNAME" > "$DUMPFILE"

  # Check if the dump was successful
  if [ $? -eq 0 ]; then
    echo "Database dump successful. File created: $DUMPFILE"
  else
    echo "Database dump failed."
    exit 1
  fi
}

function Postgres_backup()
{
  # Extract the values from the config.inc.php file
  USERNAME=$(grep '^username =' "$CONFIG_FILE" | awk -F' = ' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r\n')
  PASSWORD=$(grep '^password =' "$CONFIG_FILE" | awk -F' = ' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r\n')
  DBNAME=$(grep '^name =' "$CONFIG_FILE" | awk -F' = ' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r\n')

  # Check if all required fields are found
  if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$DBNAME" ]; then
    echo "Missing one or more required fields (username, password, name) in config.inc.php."
    exit 1
  fi

  # Create the dump filename
  DUMPFILE="$PKP_BACKUP_PATH/${DBNAME}_${DATE}.sql"

  # Perform the database dump
  PGPASSWORD="$PASSWORD" /usr/pgsql-17/bin/pg_dump -h localhost --inserts --format p --username="$USERNAME" -f "$DUMPFILE" $DBNAME

  # Check if the dump was successful
  if [ $? -eq 0 ]; then
    echo "Database dump successful. File created: $DUMPFILE"
  else
    echo "Database dump failed."
    exit 1
  fi
}

function Files_backup()
{
  # extract the values from the config.inc.php file
  PKP_PRIVATE_PATH=$(grep '^files_dir =' "$CONFIG_FILE" \
      | awk -F' = ' '{print $2}' \
      | sed 's/^[ \t]*//;s/[ \t]*$//' \
      | tr -d '\r\n' \
      | sed 's/^"\(.*\)"$/\1/')

  # check if PKP_PRIVATE_PATH was found
  if [ -z "$PKP_PRIVATE_PATH" ] ; then
    echo "Missing files_dir value in config.inc.php file."
    exit 1
  fi

  # check all required variables are found
  if [ -z "$PKP_BACKUP_PATH" ] || [ -z "$PKP_WEB_PATH" ] || [ -z "$OLD_VERSION" ]; then
    echo "Missing one or more required variables (PKP_BACKUP_PATH, PKP_WEB_PATH, OLD_VERSION). Please set these fields in the .env file."
    exit 1
  fi

  tar cvzf "$PKP_BACKUP_PATH/ojs_private-$DATE.tgz" -C "$PKP_PRIVATE_PATH" .

  tar cvzf "$PKP_BACKUP_PATH/ojs_application-$DATE.tgz" -C "$PKP_WEB_PATH" .
}

############################################################
############################################################
# main program                                             #
############################################################
############################################################

# error message for no flags
if (( $# == 0 )); then
    Help
    exit 1
fi

# get the options
while getopts ":lhdpfb" flag; do
   case $flag in
      l) # display License
        License
        exit;;
      h) # display Help
        Help
        exit;;
      d) # backup MySQL / MariaDB database
        MariaDB_backup
        exit;;
      p) # backup PostgreSQL database
        Postgres_backup
        exit;;
      f) # backup files
        Files_backup
        exit;;
      b) # backup database and files
        MariaDB_backup
        Files_backup
        exit;;
      \?) # invalid option
        Help
        exit;;
   esac
done