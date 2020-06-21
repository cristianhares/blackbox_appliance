#!/bin/bash
# Download wget for specific OS distro
# Author: Cristian H. Ares (https://www.linkedin.com/in/cares/)

# TODO: Download specific binaries for ISO version
case $CURRENT_OS in
	*"centos"* | *"fedora"* | *"red hat"*)
        # If RHEL, check if system is registered before proceeding
        if [ ! -e "/etc/sysconfig/rhn/systemid" ] && [[ "$CURRENT_OS" =~ "red hat" ]]; then
            echo "ERROR: RHEL system is not registered, please register it first"
            echo "----------------------------------------------------------------------"
            # Remove extracted data
            rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
            exit 1
        fi
		yum -y -q install wget >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
	;;
	*"ubuntu"* | *"debian"*)
        apt-get update
        apt-get -q install wget >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
	;;
	*"suse"* | *"sles"*)
        # If Sles, check if system is registered before proceeding
        if [[ ! -e "/var/cache/SuseRegister/lastzmdconfig.cache" || ! -e "/etc/SUSEConnect" ]] && [[ "$CURRENT_OS" =~ "sles" ]]; then
            echo "ERROR: SLES system is not registered, please register it first"
            echo "----------------------------------------------------------------------"
            # Remove extracted data
            rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
            exit 1
        fi
        zypper refresh
        zypper install -y wget >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
	;;
	*)
		echo "ERROR: Unknown OS Distro detected, finishing process"
		echo "----------------------------------------------------------------------"
        exit 1
	;;
esac