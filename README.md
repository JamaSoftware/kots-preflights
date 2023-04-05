# KOTS Installation preflights

## Purpose
It's necessary to validate the customer environment before a KOTS installation to prevent issues during the installation. In this repository, you can find the files needed for validating the application server and database server requirements.


## This repository is divided in 4 folders:

### base

    contains the files to run the preflights using the internet, these files have the logic to work on Linux, macOS, and Linux.
### mac

    contains the files to run the airgap preflights for macOS (development env).
### linux

    contains the files to run the airgap preflights for Linux (development and customer env)
### windows

    contains the files to run the airgap preflights for Windows server (only DB server)




## Application Server


### Airgap preflights
    Depending on the OS where you need to install the application server select a folder (mac or linux).
    Download the files "airgap-application-server_<OS>.sh" and "airgap-host-preflight_<OS>.tar.gz"  (OS stands for the operative system, the folder you chose)

    Those files must be placed in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-application-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-application-server_<OS>.sh



### Online preflights
    curl -s https://github.com/JamaSoftware/kots-preflights/blob/main/base/application-server.sh | sudo bash


## Database Server

### Airgap preflights
    Depending on the OS where you need to install the application server select a folder (mac,linux or windows).
    Download the files "airgap-database-server_<OS>.sh" and "airgap-database-preflight_<OS>.tar.gz"  (OS stands for the operative system, the folder you chose)

    Those files must be place in the same directory to work.
    Execute this command:
        chmod +x <path to the files>/airgap-database-server_<OS>.sh
    
    To run the preflights:
        sudo bash <path to the files>/airgap-databse-server_<OS>.sh



### Online preflights
    curl -s https://github.com/JamaSoftware/kots-preflights/blob/main/base/database-server.sh | sudo bash
