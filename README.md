UCK-scripts
===========

## Written to be used on Virtual Machines on the OSgenie ISO update server
https://github.com/OSgenie/ISO-update-server

## A collection of scripts for customizing Ubuntu based LiveCD isos as a cron job
Scripts consist of two categories
    1. Scripts for extracting and packaging isos
    2. Scripts to be run inside the chroot environment to customize an iso
    
## Includes the following files
### install-UCK-scripts-to-crontab.sh
Installs the scripts and creates a crontab to run isoupdate-auto @reboot
### chroot
directory for chroot scripts
### isoupdate-auto-list-dist.sh
Updates isos to latest version of all files including kernel. Creates both a version for Live PXE booting and one for OEM installation.

This is the default installed script, requires that the "generate-update-lists.sh" script has been run on the ISO-PXE server to identify available isos.
### isoupdate-auto-dist.sh
Does the same as the isoupdate-auto-list-dist.sh except will automaticly update isos but only with the Ubuntu default naming scheme
### isoupdate-auto.sh
Does the same as isoupdate-auto-dist.sh except doesn't update the kernel
### isoupdate-bash.sh
Used for testing out chroot scripts
### isoupdate-alternative.sh
Work in progress - for modifying server and alternate isos