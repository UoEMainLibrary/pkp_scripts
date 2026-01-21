#  University of Edinburgh library publishing PKP scripts

This repository contains various scripts for performing functions against University of Edinburgh's Open Journal Systems and Open Monograph Press installations. These functions include backups and upgrades.

Edinburgh Diamond, situated within Edinburgh University Library, offers free publishing services to support Diamond Open Access books and journals created by University of Edinburgh academics and students. https://library.ed.ac.uk/research-support/edinburgh-diamond

Edinburgh University Library offers a journal and book hosting service to members of the Scottish Confederation of University & Research Libraries (SCURL), as well as external organisations. https://library.ed.ac.uk/research-support/open-hosting-service. 

## backup_pkp_site.sh

backup_pkp_site.sh performs a backup of an OJS or OMP instance's database and files. Note that this is primarily designed for use with MySQL / MariaDB databases so substitute in the Postgres_backup function in the main program flow for flag b if you need to use it against a Postgres database. 

### usage

`./backup_pkp_site.sh [-l|h|d|p|f|b]`

options:
- `-l`     print the MIT License notification
- `-h`     print this Help
- `-d`     backup MySQL / MariaDB database
- `-p`     backup PostgreSQL database
- `-f`     backup website files
- `-b`     full backup of database and files