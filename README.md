#  University of Edinburgh library publishing PKP scripts

This repository contains various scripts for performing functions against University of Edinburgh's Open Journal Systems and Open Monograph Press installations. These functions include backups and upgrades.

Edinburgh Diamond, situated within Edinburgh University Library, offers free publishing services to support Diamond Open Access books and journals created by University of Edinburgh academics and students. https://library.ed.ac.uk/research-support/edinburgh-diamond

Edinburgh University Library offers a journal and book hosting service to members of the Scottish Confederation of University & Research Libraries (SCURL), as well as external organisations. https://library.ed.ac.uk/research-support/open-hosting-service. 

## .env

First copy the .env.template file to .env and fill in the variables for the particular PKP instance you are backing up.

## backup_pkp_site.sh

backup_pkp_site.sh performs a backup of an OJS or OMP instance's database and files. Note that this is primarily designed for use with MySQL / MariaDB databases so substitute in the Postgres_backup function in the main program flow for flag -b if you need to use it against a Postgres database. 

backup_pkp_site.sh requires the PKP_WEB_PATH and OLD_VERSION variables to be filled in .env.

### usage

`./backup_pkp_site.sh [-l|h|d|p|f|b]`

options:
- `-l`     print the MIT License notification
- `-h`     print this Help
- `-d`     backup MySQL / MariaDB database
- `-p`     backup PostgreSQL database
- `-f`     backup website files
- `-b`     full backup of database and files

## upgrade_pkp_site.sh

upgrade_pkp_site.sh performs an upgrade of an OJS or OMP instance including putting the site in maintenance mode, installing a new version of OJS or OMP and copying back required files, and upgrading the OJS or OMP database. 

upgrade_pkp_site.sh requires all the variables to be filled in .env.

### usage

`./upgrade_pkp_site.sh [-l|h|m|e|i||c|u]`

options:
- `-l`     print the MIT License notification
- `-h`     print this Help
- `-m`     put website into maintenance mode
- `-e`     turn off maintenance mode
- `-i`     install new version of OJS or OMP
- `-c`     check upgrade for OJS or OMP database
- `-u`     upgrade OJS or OMP database

To run a full upgrade, run the commands in the following order. Be sure to check that this is working for your environment throughout the process:

- `./upgrade_pkp_site.sh -m`
- `./upgrade_pkp_site.sh -i`
- `./upgrade_pkp_site.sh -u`
- `./upgrade_pkp_site.sh -e`