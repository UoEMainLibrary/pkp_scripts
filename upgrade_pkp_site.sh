#!/bin/bash
# @name: upgrade_pkp_site.sh
# @creation_date: 2025-01-21
# @license: The MIT License <https://opensource.org/licenses/MIT>
# @author: Ronan Burnett
# @author: Simon Bowie <simonxix@simonxix.com>
# @purpose: upgrade up a OJS / OMP database and website
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
   echo "This script upgrades up an OJS or OMP database and website."
   echo
   echo "Syntax: upgrade_pkp_site.sh [-l|h|m|e|i||c|u]"
   echo "options:"
   echo "l     print the MIT License notification"
   echo "h     print this Help"
   echo "m     put website into maintenance mode"
   echo "e     turn off maintenance mode"
   echo "i     install new version of OJS or OMP"
   echo "c     check upgrade for OJS or OMP database"
   echo "u     upgrade OJS or OMP database"
   echo
}

# a function to prompt the user before each step
function Prompt_user() {
    echo "----"
    read -p "Proceed with step $1 ? [y/n]: " -n 1 -r REPLY
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Exiting without completing step $1."
        exit 1
    fi
}

function Enter_maintenance_mode()
{
   # put site into maintenance mode
   cp "$PKP_WEB_PATH/.htaccess" "$PKP_WEB_PATH/.htaccess-$DATE"

   cat > "$PKP_WEB_PATH/.htaccess" <<EOL
order deny,allow
deny from all
ErrorDocument 403 "This site is undergoing maintenance and should return shortly. Thank you for your patience."
EOL

  echo "Site is now IN maintenance mode"
}

function Exit_maintenance_mode()
{
   mv "$PKP_WEB_PATH/.htaccess-$DATE" "$PKP_WEB_PATH/.htaccess"

  echo "Site is now NOT IN maintenance mode"
}

function Download_release_package()
{
    wget -P $PKP_ROOT_PATH "https://pkp.sfu.ca/$PKP_SOFTWARE/download/$PKP_SOFTWARE-$NEW_VERSION.tar.gz"
}

function Install_release_package()
{
    # move the live directory out of the way as a further backup
    # and also so we can unpack the new files into a clean location
    mv "$PKP_WEB_PATH" "$PKP_WEB_PATH-$OLD_VERSION"

    # recreate the live directory
    mkdir "$PKP_WEB_PATH"

    # install the new files
    tar --strip-components=1 -xvzf "$PKP_ROOT_PATH/$PKP_SOFTWARE-$NEW_VERSION.tar.gz" -C "$PKP_WEB_PATH"
}

function Copy_previous_files()
{
    # copy back the healthcheck if that directory exists
    if [ -d "$PKP_WEB_PATH-$OLD_VERSION/healthcheck" ]; then
        rsync -av "$PKP_WEB_PATH-$OLD_VERSION/healthcheck/" "$PKP_WEB_PATH/healthcheck/"
    fi

    # copy back the config
    cp "$PKP_WEB_PATH-$OLD_VERSION/config.inc.php" "$PKP_WEB_PATH"

    # copy back the previous .htaccess file
    cp "$PKP_WEB_PATH-$OLD_VERSION/.htaccess-$DATE" "$PKP_WEB_PATH"

    # copy back the 'public' directory
    rsync -av "$PKP_WEB_PATH-$OLD_VERSION/public/" "$PKP_WEB_PATH/public"

    # copy back the 'maintenance' .htaccess file
    cp "$PKP_WEB_PATH-$OLD_VERSION/.htaccess" "$PKP_WEB_PATH"

    # set permissions
    chown -R $WEB_USER:$WEB_GROUP "$PKP_WEB_PATH"
    chown $WEB_USER:$WEB_GROUP "$PKP_WEB_PATH/.htaccess"

    # remove installation package
    rm "$PKP_ROOT_PATH/$PKP_SOFTWARE-$NEW_VERSION.tar.gz"

    # show reminder to match up config.inc.php with new config.TEMPLATE.inc.php
    echo "Remember to MANUALLY match up config.inc.php with config.TEMPLATE.inc.php to add or remove any configuration options as necessary."
}

function Upgrade_check()
{
    php "$PKP_WEB_PATH/tools/upgrade.php" check
}

function Upgrade()
{
    # the memory limit might need to be tweaked. See PKP instructions page for more details.
    # php -d memory_limit=2048M tools/upgrade.php upgrade
    #nohup php "$PKP_WEB_PATH/tools/upgrade.php" upgrade > $PKP_BACKUP_PATH/upgrade.log &
    #echo "*** PROCEED ONLY WHEN SURE PROCESS HAS COMPLETED ***"
    #echo "Monitor $PKP_BACKUP_PATH/upgrade.log and wait for completion."
    php "$PKP_WEB_PATH/tools/upgrade.php" upgrade
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
while getopts ":lhmeicu" flag; do
   case $flag in
      l) # display License
        License
        exit;;
      h) # display Help
        Help
        exit;;
      m) # put site into maintenance mode
        Enter_maintenance_mode
        exit;;
      e) # exit maintenance mode
        Exit_maintenance_mode
        exit;;
      i) # install new version
        Download_release_package
        Install_release_package
        Copy_previous_files
        exit;;
      c) # upgrade check
        Upgrade_check
        exit;;
      u) # upgrade database
        Upgrade_check
        Prompt_user "upgrade database"
        Upgrade
        exit;;
      \?) # invalid option
        Help
        exit;;
   esac
done