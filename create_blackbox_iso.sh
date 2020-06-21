#!/bin/bash
# Create the blackbox appliance ISO file.
# Author: Cristian H. Ares (https://www.linkedin.com/in/cares/)

#-------------------------------------------------------------------------------------------
# EDIT FROM HERE
# Environment variables for ISO creation
HOME_DIR=$(pwd)
CONFIG_INPUT_DIR=config_input
SUPPORTING_BINS=bin
ISO_INPUT_DIR=iso_input
ISO_MOUNT_DIR=iso_mount
ISO_EXTRACT_DIR=iso_extract
ISO_EXTRAS_DIR=extras
ISO_OUTPUT_DIR=iso_output
ISO_OUTPUT_NAME=bbappliance.iso
CUSTOM_PACKAGES=extras
TEMPLATES_DIR=templates
LOG_FILE_DIR=logs
LOG_FILE_NAME=bbappliance_iso.log

# ISO download variables
ISO_MIRROR_URL="http://mirror.xnet.co.nz/pub/centos/" # Change to your closest mirror
ISO_MIRROR_FILE="CentOS-7-x86_64-Minimal-2003.iso" # Change to the chosen distro ISO file name
ISO_RELEASE="7.8.2003" # Change to the specific ISO release
ISO_ARCH="x86_64"
ISO_GPG_KEY="RPM-GPG-KEY-CentOS-7" # Change to the non-dev GPG Key inside the ISO
ISO_FILE_URI="/isos/$ISO_ARCH"
ISO_PACKS_URI="/os/$ISO_ARCH/"
ISO_UPDATES_URI="/updates/$ISO_ARCH/"

# Packages required for ISO
PACKAGES_SYSTEM="hyperv-daemons open-vm-tools wget nano aide tcp_wrappers"

# Template to use from TEMPLATES_DIR for hardening system
# Note: Some hardening options are set via the ks.cfg
HARDENING_TEMPLATE=template_CIS_Centos7.sh

# Customization variables
# TODO: Not yet implemented
MAIN_NAME="BlackBox Appliance"

# Password variables for bootloader and root, it will be hashed later
PASSWORD_BOOTLOADER="ApplBoot01!"
PASSWORD_ROOT="Appliance01!"

# Password variables for users, they will be asked to be changed on first login
PASSWORD_SYSADMIN="Appliance02!"
PASSWORD_NETADMIN="Appliance03!"

# System configuration variables
SYSTEM_FQDN_HOSTNAME=""
SYSTEM_PROXY=""

# Syslog destination configuration for rsyslog collector template
SYSLOG_DESTINATION="dest123"
SYSLOG_DESTINATION_PORT="6514"
SYSLOG_DESTINATION_PROTOCOL="TCP" # Set to UDP for change in protocol
SYSLOG_DESTINATION_TLS="NO" # Set to YES if destinations is unauth TLS

# Syslog trusted CA certs file location, copy your pem file to the $CONFIG_INPUT_DIR directory
SYSLOG_TRUST_CERTS="/etc/rsyslog/syslogca.pem"

# Syslog cache for forwarding, set around 70% of disk space % set in ks.cfg and computer disk.
SYSLOG_CACHE_DIR="/var/log/syslog"
SYSLOG_CACHE_SIZE="4g" # Set as XXg in gigabytes

# MS Azure template variables
AZ_WORKSPACE_ID=""
AZ_SHARED_KEY=""

# TO HERE
#-------------------------------------------------------------------------------------------

usage()
{
    echo "usage: $1 [OPTIONS]"
    echo "Options:"
    echo "  -d   | --default             default ISO creation process."
	echo "  -s   | -syslogcollector      ISO with RSyslog syslog collector appliance."
    echo "  -azs | --azuresentinel       ISO with Azure Sentinel CEF collector & OMS Agent."
	echo "                               Note: requires the workspace ID and shared key set in script"
    echo "  -?   | -h | --help           shows this usage text."
}

# Obtain OS details from the /etc/os-release
CURRENT_OS=$(awk -F'"' '/^NAME=/{print tolower($2)}' /etc/os-release)
CURRENT_MAJOR=$(awk -F'"' '/^VERSION_ID=/{print tolower($2)}' /etc/os-release)


# Create required directories if missing
if [ ! -e "$HOME_DIR/$LOG_FILE_DIR" ]; then
	mkdir $HOME_DIR/$LOG_FILE_DIR
fi

if [ ! -e "$HOME_DIR/$ISO_MOUNT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_MOUNT_DIR
fi

if [ ! -e "$HOME_DIR/$ISO_EXTRACT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_EXTRACT_DIR
fi

if [ ! -e "$HOME_DIR/$ISO_OUTPUT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_OUTPUT_DIR
fi

if [ ! -e "$HOME_DIR/$CUSTOM_PACKAGES" ]; then
	mkdir $HOME_DIR/$CUSTOM_PACKAGES
fi

if [ ! -e "$HOME_DIR/$ISO_INPUT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_INPUT_DIR
fi


# Create log file or reload it
if [ -e "$HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME" ]; then
	rm -f $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME
	touch $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME
else
	touch $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME
fi


# Make a choice based on parameters passed to the script
if [ $# -ne 0 ]; then
    case "$1" in
		# Default ISO creation
        -d|--default)
			echo "----------------------------------------------------------------------"
            echo "INFO: Running ISO creation process as default template"
			echo "----------------------------------------------------------------------"
			TEMPLATE="default"
            ;;
		# ISO that later installs Azure Sentinel CEF collector & OMS Agent in the sytem.
        -azs|--azuresentinel)
			echo "----------------------------------------------------------------------"
            echo "INFO: Running ISO creation with MS Azure Sentinel collector template"
			echo "----------------------------------------------------------------------"
			TEMPLATE="msazsentinel"
            ;;
		# ISO that later installs and configures a syslog collector.
        -s|--syslogcollector)
			echo "----------------------------------------------------------------------"
            echo "INFO: Running ISO creation with the rsyslog collector template"
			echo "----------------------------------------------------------------------"
			TEMPLATE="rsyslogcollector"
            ;;
		# Print the help message
        -\? | -h | --help)
            usage `basename $0` >&2
            exit 0
            ;;
    esac
else
	# No argument was passed
    echo "Unknown argument: '$1'" >&2
    echo "Use -h or --help for usage" >&2
    exit 1
fi


# Check if ISO exists, and if not, download it into the ISO_INPUT_DIR folder
ISO_INPUT_FILE=$HOME_DIR/$ISO_INPUT_DIR/$ISO_MIRROR_FILE

if ! [ -e "$ISO_INPUT_FILE" ]; then
    echo "PROCESSING: Input ISO not found, downloading CentOS7 minimal ISO"
	echo "----------------------------------------------------------------------"
	if which wget >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1; then
		wget -O $ISO_INPUT_FILE $ISO_MIRROR_URL$ISO_RELEASE$ISO_FILE_URI$ISO_MIRROR_FILE
	else
		source $HOME_DIR/$SUPPORTING_BINS/download_wget.sh
		wget -O $ISO_INPUT_FILE $ISO_MIRROR_URL$ISO_RELEASE$ISO_FILE_URI$ISO_MIRROR_FILE
	fi
else
    echo "INFO: Input ISO already found in $HOME_DIR/$ISO_INPUT_DIR/"
	echo "----------------------------------------------------------------------"
fi

# Mount ISO and extract its contents with all files including hidden ones
echo "PROCESSING: Mounting ISO file and copying content to temporary directory"
echo "----------------------------------------------------------------------"

mount -t iso9660 -o loop $ISO_INPUT_FILE $HOME_DIR/$ISO_MOUNT_DIR/ >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
cp -arf $HOME_DIR/$ISO_MOUNT_DIR/* $HOME_DIR/$ISO_EXTRACT_DIR/
umount $HOME_DIR/$ISO_MOUNT_DIR/

# Fix for cases where the isolinux files are not allowed to be replaced
chmod 777 -R $HOME_DIR/$ISO_EXTRACT_DIR/

echo "INFO: ISO has been dismounted"
echo "----------------------------------------------------------------------"


# Get the OS to determine package manager, and install dependencies
echo "INFO: Determining OS and downloading required binaries"
echo "----------------------------------------------------------------------"
source $HOME_DIR/$SUPPORTING_BINS/detect_os.sh


# Download the updates for the ISO packages if yum and yum-utils is present
if which yum >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1 && which repoquery >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1 ; then
	echo "PROCESSING: Downloading Updates for the used ISO and adding them"
	echo "----------------------------------------------------------------------"
	source $HOME_DIR/$SUPPORTING_BINS/download_iso_updates.sh
else
	echo "INFO: No YUM was detected in system, skipping updates download"
	echo "----------------------------------------------------------------------"
fi


# If the cp alias exists, remove the -i most systems aliases in the bash profile, and later reactivate
if alias cp 2>/dev/null; then
	unalias cp
	ALIAS_EXISTED="1"
fi


# Verify the kickstart file
echo "PROCESSING: Verifying kickstart file"
echo "----------------------------------------------------------------------"
if [[ $(ksvalidator $HOME_DIR/$CONFIG_INPUT_DIR/ks.cfg) = *error* ]]; then
	echo "ERROR: Error in kickstart file validation, validate your file with ksvalidator"
	echo "----------------------------------------------------------------------"
	# Remove extracted data
	rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
	exit 1
fi
if [[ $(ksvalidator $HOME_DIR/$CONFIG_INPUT_DIR/ks.cfg) = *deprecated* ]]; then
	echo "ERROR: Deprecated command in kickstart file validation, validate your file with ksvalidator"
	echo "----------------------------------------------------------------------"
	# Remove extracted data
	rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
	exit 1
fi


# Copy customized files into the respective folder
echo "PROCESSING: Copying customized files to temporary directory"
echo "----------------------------------------------------------------------"

cp $HOME_DIR/$CONFIG_INPUT_DIR/isolinux.cfg $HOME_DIR/$ISO_EXTRACT_DIR/isolinux/isolinux.cfg
cp $HOME_DIR/$CONFIG_INPUT_DIR/splash.png $HOME_DIR/$ISO_EXTRACT_DIR/isolinux/splash.png
cp $HOME_DIR/$CONFIG_INPUT_DIR/grub.cfg $HOME_DIR/$ISO_EXTRACT_DIR/EFI/BOOT/grub.cfg

# Search the password settings commands in the base ks.cfg and replace the $6 SHA512 Hashes with the new ones in the new file in ISO_EXTRACT_DIR
python3 $HOME_DIR/$SUPPORTING_BINS/password_replacer.py $HOME_DIR/$CONFIG_INPUT_DIR/ks.cfg $HOME_DIR/$ISO_EXTRACT_DIR/ks.cfg $PASSWORD_ROOT $PASSWORD_SYSADMIN $PASSWORD_NETADMIN


# Set the bootloader password
PASS_BOOTLOADER_PBKDF2=$(echo -e "$PASSWORD_BOOTLOADER\n$PASSWORD_BOOTLOADER" | grub2-mkpasswd-pbkdf2 | awk '/grub.pbkdf/{print$NF}')

sed -i "s|^bootloader.*|bootloader --iscrypted --password=$PASS_BOOTLOADER_PBKDF2|g" $HOME_DIR/$ISO_EXTRACT_DIR/ks.cfg


# Check for extra RPMs and reconstruct the repos
rpmcount=`ls -1 $HOME_DIR/$CUSTOM_PACKAGES/*.rpm 2>/dev/null | wc -l`

if [ $rpmcount != 0 ]; then
	echo "PROCESSING: Copying RPM files to ISO repository"
	echo "----------------------------------------------------------------------"

	# Copy custom packages from the extras folder to add to the ISO repository if there are any
	cp $HOME_DIR/$CUSTOM_PACKAGES/*.rpm $HOME_DIR/$ISO_EXTRACT_DIR/Packages/ >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

	echo "PROCESSING: Rebuilding repository metadata"
	echo "----------------------------------------------------------------------"

	# Update the ISO yum repository with the added packages
	for repofile in $HOME_DIR/$ISO_EXTRACT_DIR/repodata/*minimal*comps.xml; do
		createrepo -g $repofile $HOME_DIR/$ISO_EXTRACT_DIR/ --update >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
	done
fi


# Create the custom scripts folder before ISO creation
if [ ! -e "$HOME_DIR/$ISO_EXTRACT_DIR/scripts" ]; then
	mkdir $HOME_DIR/$ISO_EXTRACT_DIR/scripts
fi


# Create the extra files folder before ISO creation
if [ ! -e "$HOME_DIR/$ISO_EXTRACT_DIR/$ISO_EXTRAS_DIR" ]; then
	mkdir $HOME_DIR/$ISO_EXTRACT_DIR/$ISO_EXTRAS_DIR
fi


# Copy the customization service and script to the ISO extract folder
cp $HOME_DIR/$CONFIG_INPUT_DIR/bootstrap_install.service $HOME_DIR/$ISO_EXTRACT_DIR/scripts >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
cp $HOME_DIR/$CONFIG_INPUT_DIR/post_installation.sh $HOME_DIR/$ISO_EXTRACT_DIR/scripts >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1


# Set hostname on first boot if variable length is greater than 1
if [ ${#SYSTEM_FQDN_HOSTNAME} -ge 1 ]; then
	echo "hostname $SYSTEM_FQDN_HOSTNAME" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
fi


# Set Hardening template to system
cat $HOME_DIR/$TEMPLATES_DIR/$HARDENING_TEMPLATE >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

case $TEMPLATE in
	"msazsentinel")
		# TODO: MS AZ Sentinel CEF configuration Script doesn't support a proxy as the OMS agent installation does,
		# TODO: This asumes the box has direct internet connectivity.
		# TODO: The sysadmin user can change the OMS agent proxy configuration later on.
		if [ ${#AZ_WORKSPACE_ID} -ge 10 ] && [ ${#AZ_SHARED_KEY} -ge 10 ] && [ ${#SYSTEM_FQDN_HOSTNAME} -ge 1 ]; then
			source $HOME_DIR/$TEMPLATES_DIR/template_msaz_sentinel.sh
			echo "INFO: Microsoft Azure Sentinel template files copied"
			echo "----------------------------------------------------------------------"
		else
			echo "ERROR: Azure Workspace ID, Shared Key or hostname are wrongly set"
			echo "----------------------------------------------------------------------"
			echo "INFO: Check your MS Azure variables and try again"
			echo "----------------------------------------------------------------------"
			# Remove extracted data
			rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*

			# Restore alias if existed
			if [ "$ALIAS_EXISTED"="1" ]; then
				alias cp='cp -i'
			fi
			exit 1
		fi

		echo "INFO: Microsoft Azure Sentinel template files copied"
		echo "----------------------------------------------------------------------"
	;;
	"rsyslogcollector")
		if [ ${#SYSLOG_DESTINATION} -lt 1 ]; then
			echo "ERROR: Syslog collector destination is not set, check input"
			echo "----------------------------------------------------------------------"
			# Remove extracted data
			rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
			exit 1
		else
			source $HOME_DIR/$TEMPLATES_DIR/template_rsyslog_collector.sh

			if [[ $SYSLOG_DESTINATION_TLS == "YES" ]]; then
				if ! [ -e "$HOME_DIR/$CONFIG_INPUT_DIR/syslogca.pem" ]; then
					echo "TLS syslog was set but no CA file was found, check input"
					echo "----------------------------------------------------------------------"
					# Remove extracted data
					rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
					exit 1
				else
					cp $HOME_DIR/$CONFIG_INPUT_DIR/syslogca.pem $HOME_DIR/$ISO_EXTRACT_DIR/$ISO_EXTRAS_DIR/syslogca.pem
				fi
			fi

			echo "INFO: Syslog collector template files copied"
			echo "----------------------------------------------------------------------"
		fi
	;;
	*)
		source $HOME_DIR/$TEMPLATES_DIR/template_default.sh
		echo "INFO: Default customization files copied"
		echo "----------------------------------------------------------------------"
	;;
esac


# Restore alias if existed
if [ "$ALIAS_EXISTED"="1" ]; then
	alias cp='cp -i'
fi


# Create the ISO and remove the extracted files
echo "PROCESSING: Creating ISO File"
echo "----------------------------------------------------------------------"

ISO_OUTPUT_FILE=$HOME_DIR/$ISO_OUTPUT_DIR/$ISO_OUTPUT_NAME

# Check if ISO exists from previous generation
if [ -e "$ISO_OUTPUT_FILE" ]; then
	if ! rm -f $ISO_OUTPUT_FILE >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1; then
		echo "ERROR: Failed to remove old ISO file, check the log"
		echo "----------------------------------------------------------------------"
		# Remove extracted data
		rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
		exit 1
	else
		genisoimage -r -T -J -V "OEMDRV" -input-charset utf-8 -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -R -J -o $ISO_OUTPUT_FILE $HOME_DIR/$ISO_EXTRACT_DIR >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
   		echo "OK: ISO successfully created in $HOME_DIR/$ISO_OUTPUT_DIR/"
		echo "----------------------------------------------------------------------"
	fi
else
	genisoimage -r -T -J -V "OEMDRV" -input-charset utf-8 -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -R -J -o $ISO_OUTPUT_FILE $HOME_DIR/$ISO_EXTRACT_DIR >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
    echo "OK: ISO successfully created in $HOME_DIR/$ISO_OUTPUT_DIR/"
	echo "----------------------------------------------------------------------"
fi


# Remove extracted data
rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*