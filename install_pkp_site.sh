#!/bin/bash
# @name: install_pkp_site.sh
# @creation_date: 2026-02-12
# @license: The MIT License <https://opensource.org/licenses/MIT>
# @author: Simon Bowie <simonxix@simonxix.com>
# @purpose: install an OJS / OMP instance
# @acknowledgements:
# https://docs.pkp.sfu.ca/admin-guide/en/getting-started
# https://medium.com/@musaamin/install-ojs33-ubuntu2204-step-by-step-tutorial-c871f452616f
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
   echo "This script installs an OJS or OMP instance."
   echo
   echo "Syntax: install_pkp_site.sh [-l|h|i]"
   echo "options:"
   echo "l     print the MIT License notification"
   echo "h     print this Help"
   echo "i     install application"
   echo
}

function Download_release_package()
{
    wget -P $PKP_ROOT_PATH "https://pkp.sfu.ca/$PKP_SOFTWARE/download/$PKP_SOFTWARE-$NEW_VERSION.tar.gz"
}

function Install_release_package()
{
    # create the live directory
    mkdir "$PKP_WEB_PATH"

    # install the new files
    tar --strip-components=1 -xvzf "$PKP_ROOT_PATH/$PKP_SOFTWARE-$NEW_VERSION.tar.gz" -C "$PKP_WEB_PATH"

    # set permissions
    chown -R $WEB_USER:$WEB_GROUP "$PKP_WEB_PATH"
    chown $WEB_USER:$WEB_GROUP "$PKP_WEB_PATH/.htaccess"

    # remove installation package
    rm "$PKP_ROOT_PATH/$PKP_SOFTWARE-$NEW_VERSION.tar.gz"
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
while getopts ":lhi" flag; do
   case $flag in
      l) # display License
        License
        exit;;
      h) # display Help
        Help
        exit;;
      i) # install application
        Download_release_package
        Install_release_package
        exit;;
      \?) # invalid option
        Help
        exit;;
   esac
done