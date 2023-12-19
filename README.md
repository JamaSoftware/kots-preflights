# KOTS Installation preflights

## Purpose
It's necessary to validate the environment before a KOTS installation to prevent issues. In this repository, you can find the files needed for validating the application server and database server requirements.


## This repository is divided into 2 version folders:

:bangbang:**V2 - This contains the validations needed for the latest and future Jama KOTS Versions. Please, check the compatible Jama versions:**:bangbang:
* 8.79.6+
* 9.0.4+
* 9.6.2+

**V1 - This contains the validations for these Jama versions:**
* 8.79.0 - 8.79.5
* 9.0.1 - 9.0.3


# non-Airgap

    Execute the next commands on your application/database server

* ### Application Server
  * ### V2

    `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/non-airgap/application-server.sh | sudo bash`

  * ### V1
    `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/non-airgap/application-server.sh | sudo bash`

* ### Database Server

  * ### V2
    `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v2/non-airgap/database-server.sh | sudo bash`

  * ### V1
    `curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/v1/non-airgap/database-server.sh | sudo bash`


# Airgap
In this folder, you can find the files to check your environment without the internet (airgap).


## Application Server
Depending on the OS where you need to install the application server select a folder (mac or linux).
Download the files "airgap-application-server_<OS>.sh" and "airgap-host-preflight_<OS>.tar.gz"  (OS stands for the operative system, the folder you chose)

> Note:  
>Execute these commands to download the files and copy them to the application server.

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
Depending on the OS where you need to install the application server select a folder (mac,linux or windows).
Download the files "airgap-database-server_<OS>.sh" and "airgap-database-preflight_<OS>.tar.gz"  (OS stands for the operative system, the folder you chose)


> Note:  
>Execute these commands to download the files and copy them to the database server.

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
For running the database preflights you need to install 7zip to unzip the files, by default the airgap-database-server_windows.bat will use the disk C:
