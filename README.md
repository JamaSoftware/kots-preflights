# KOTS Installation preflights

## Purpose
It's necessary to validate the environment before a KOTS installation to prevent issues. In this repository, you can find the files needed for validating the application server and database server requirements.


## This repository is divided into 3 version folders:

:bangbang:**V3 - This version contains the validations needed for the latest and future Jama KOTS Versions. V3 adds validation for new database character set and collation requirements. Please confirm Jama Connect version compatibility before running:**:bangbang:
* 9.17.0+

**V2 - This contains the validations for these Jama versions:**
* 8.79.6+
* 9.0.4+
* 9.6.2+

**V1 - This contains the validations for these Jama versions:**
* 8.79.0 - 8.79.5
* 9.0.1 - 9.0.3


# non-Airgap

    Execute the next commands on your application/database server

* ### Application Server
    * ### V3
      :bangbang: You must have `wget` installed in your machine to run this script.

      `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/non-airgap/application-server.sh | sudo bash`

    * ### V2
      `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/non-airgap/application-server.sh | sudo bash`

    * ### V1
      `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/non-airgap/application-server.sh | sudo bash`

* ### Database Server

    * ### V3
      These scripts don't alter the data stored in the database, only how the data is interpreted by the database. We still **strongly** suggest you back up your database before running the script.
      <br /><br />
      The first script checks the collation of each database table. If it's different from `utf8mb4` it will present a message suggesting that the upgrade script be run.
      <br /><br />
      The second script upgrades all the instances where the collation is different from `utf8mb4`. This script should **only** be run if prompted by the first script.
      <br /><br />
      :bangbang: You must have `wget` and `mysql` client version 8 installed in your machine to run these scripts.
      <br /><br />
      `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/non-airgap/database-server.sh | sudo bash -s -- -t <tenant_db> -i <host> -o <port_num> -u <db_user> -p <db_password>`

      ### To update the collation after the check:
      Open the folder where the files were downloaded and run:

      `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/scripts/mysqldb_collation_upgrade.sh | sudo bash -s -- -d no -t <tenant_db> -i <host> -o <port_num> -u <db_user> -p <db_password>`

    * ### V2
      `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/non-airgap/database-server.sh | sudo bash`

    * ### V1
      `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/non-airgap/database-server.sh | sudo bash`


# Airgap
In this folder, you can find the files to check your environment without the internet (airgap).


## Application Server
Download the files "airgap-application-server_linux.sh" and "airgap-host-preflight_linux.tar.gz"

> Note:  
>Execute these commands to download the files and copy them to the application server.

* ### V3
`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/airgap/linux/airgap-application-server_linux.sh --output airgap-application-server_linux.sh`

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/airgap/linux/airgap-host-preflight_linux.tar.gz --output airgap-host-preflight_linux.tar.gz`

    Execute this command:
        chmod +x ./airgap-application-server_linux.sh
    
    To run the preflights:
        sudo bash ./airgap-application-server_linux.sh

* ### V2
`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/airgap/linux/airgap-application-server_linux.sh --output airgap-application-server_linux.sh`

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/airgap/linux/airgap-host-preflight_linux.tar.gz --output airgap-host-preflight_linux.tar.gz`

    Those files must be placed in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-application-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-application-server_<OS>.sh

* ### V1

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/airgap/linux/airgap-application-server_linux.sh --output airgap-application-server_linux.sh`

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/airgap/linux/airgap-host-preflight_linux.tar.gz --output airgap-host-preflight_linux.tar.gz`

    Those files must be placed in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-application-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-application-server_<OS>.sh

## Database Server
Download the files "airgap-database-server_linux.sh", "airgap-database-preflight_linux.tar.gz" and "mysqldb_collation_upgrade.sh"


> Note:  
>Execute these commands to download the files and copy them to the database server.

* ### V3
These scripts don't alter the data stored in the database, only how the data is interpreted by the database. We still **strongly** suggest you back up your database before running the script.

The first script checks the collation of each database table. If it's different from `utf8mb4` it will present a message suggesting that the upgrade script be run.

The second script upgrades all the instances where the collation is different from `utf8mb4`. This script should **only** be run if prompted by the first script.

:bangbang: You must have `wget` and `mysql` client version 8 installed in your machine to run these scripts.

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/airgap/linux/airgap-database-server_linux.sh --output airgap-database-server_linux.sh`

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/airgap/linux/airgap-database-preflight_linux.tar.gz --output airgap-database-preflight_linux.tar.gz`

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v3/scripts/mysqldb_collation_upgrade.sh --output mysqldb_collation_upgrade.sh`

    Execute this command:
        chmod +x ./airgap-database-server_linux.sh
    
    To run the preflights:
        sudo bash ./airgap-database-server_linux.sh -t <tenant_db> -i <host> -o <port_num> -u <db_user> -p <db_password>
    
    To update the collation after the check:
        chmod +x ./mysqldb_collation_upgrade.sh
        sudo bash ./mysqldb_collation_upgrade.sh -d no -t <tenant_db> -i <host> -o <port_num> -u <db_user> -p <db_password>

* ### V2
`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/airgap/linux/airgap-database-server_linux.sh --output airgap-database-server_linux.sh`

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/airgap/linux/airgap-database-preflight_linux.tar.gz --output airgap-database-preflight_linux.tar.gz`


    Those files must be place in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-database-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-databse-server_<OS>.sh

* ### V1
`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/airgap/linux/airgap-database-server_linux.sh --output airgap-database-server_linux.sh`

`curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/airgap/linux/airgap-database-preflight_linux.tar.gz --output airgap-database-preflight_linux.tar.gz`


    Those files must be place in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-database-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-databse-server_<OS>.sh

### For Windows
Windows is not currently supported for the preflight scripts. For windows-based databases you can run the preflight scripts remotely from a linux system that has access to the database server and use the host (-i) and port number (-o) options.