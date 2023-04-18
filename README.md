# KOTS Installation preflights

## Purpose
It's necessary to validate the environment before a KOTS installation to prevent issues. In this repository, you can find the files needed for validating the application server and database server requirements.


## This repository is divided in 2 folders:


# non-Airgap

    In this folder you can find the executable files to run the preflights with an internet connection.

### Application Server
    curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/non-airgap/application-server.sh | sudo bash

### Database Server
    curl -s https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/non-airgap/database-server.sh | sudo bash

    
# Airgap
In this folder you can find the files to check your environment without internet (airgap).


### Application Server
Depending on the OS where you need to install the application server select a folder (mac or linux).
    Download the files "airgap-application-server_<OS>.sh" and "airgap-host-preflight_<OS>.tar.gz"  (OS stands for the operative system, the folder you chose)

#### curl commands
    
curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/airgap/linux/airgap-application-server_linux.sh --output airgap-application-server_linux.sh

curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/airgap/linux/airgap-host-preflight_linux.tar.gz --output airgap-host-preflight_linux.tar.gz

    Those files must be placed in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-application-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-application-server_<OS>.sh

### Database Server
Depending on the OS where you need to install the application server select a folder (mac,linux or windows).
    Download the files "airgap-database-server_<OS>.sh" and "airgap-database-preflight_<OS>.tar.gz"  (OS stands for the operative system, the folder you chose)
    
#### curl commands
    
curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/airgap/linux/airgap-database-server_linux.sh --output airgap-database-server_linux.sh
    
curl https://raw.githubusercontent.com/JamaSoftware/kots-preflights/main/airgap/linux/airgap-database-preflight_linux.tar.gz --output airgap-database-preflight_linux.tar.gz
    

    Those files must be place in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-database-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-databse-server_<OS>.sh
