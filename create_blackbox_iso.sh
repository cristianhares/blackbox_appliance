#!/bin/bash
# Create the blackbox appliance ISO file.
# Author: Cristian H. Ares (https://www.linkedin.com/in/cares/)

#---------------------------------------------------------------------------------
# EDIT FROM HERE
# Environment variables for ISO creation
HOME_DIR=$(pwd)
CONFIG_INPUT_DIR=config_input
SUPPORTING_BINS=bin
ISO_INPUT_DIR=iso_input
ISO_MOUNT_DIR=iso_mount
ISO_EXTRACT_DIR=iso_extract
ISO_OUTPUT_DIR=iso_output
ISO_OUTPUT_NAME=bbappliance.iso
CUSTOM_PACKAGES=extras
LOG_FILE_DIR=logs
LOG_FILE_NAME=bbappliance_iso.log

# ISO download variables
ISO_MIRROR_URL="http://mirror.xnet.co.nz/pub/centos/7.8.2003/"
ISO_FILE_URI="isos/x86_64/"
ISO_PACKS_URI="os/x86_64/Packages/"
ISO_MIRROR_FILE="CentOS-7-x86_64-Minimal-2003.iso"

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

# Syslog configuration, not compatible with MS Azure Sentinel template
# TODO: Not yet implemented
SYSLOG_DESTINATION=""

# MS Azure template variables
AZ_WORKSPACE_ID=""
AZ_SHARED_KEY=""

# TO HERE
#---------------------------------------------------------------------------------

usage()
{
    echo "usage: $1 [OPTIONS]"
    echo "Options:"
    echo "  -d | --default               default ISO creation process."
    echo "  -azs | --azuresentinel        ISO with Azure Sentinel CEF collector & OMS Agent."
	echo "                             Note: requires the workspace ID and shared key set in script"
    echo "  -? | -h | --help           shows this usage text."
}


# Create log file folder
if [ ! -d "$HOME_DIR/$LOG_FILE_DIR" ]; then
	mkdir $HOME_DIR/$LOG_FILE_DIR
fi


# Create log file or reload it
if [ -n "$HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME" ]; then
	rm -f $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME
	touch $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME
else
	touch $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME
fi


# Make a choice based on parameters passed
if [ $# -ne 0 ]; then
    case "$1" in
		# Default ISO creation
        -d|--default)
			echo "------------------------------------------------------------"
            echo "Running ISO creation process as default template"
			echo "------------------------------------------------------------"
			TEMPLATE="default"
            ;;
		# ISO that later installs Azure Sentinel CEF collector & OMS Agent in the sytem.
        -azs|--azuresentinel)
			echo "------------------------------------------------------------"
            echo "Running ISO creation with MS Azure Sentinel collector template"
			echo "------------------------------------------------------------"
			TEMPLATE="msazsentinel"
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


# Verify the input ISO folder exists and the ISO has been copied over
if [ ! -d "$HOME_DIR/$ISO_INPUT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_INPUT_DIR
fi

ISO_INPUT_FILE=$(find $HOME_DIR/$ISO_INPUT_DIR -name "*.iso" -exec echo {} \;)


# Check if ISO exists
if [ -z "$ISO_INPUT_FILE" ]; then
    echo "ERROR: Input ISO not found, downloading CentOS7 minimal ISO"
	echo "------------------------------------------------------------"
	wget -O $HOME_DIR/$ISO_INPUT_DIR/$ISO_MIRROR_FILE $ISO_MIRROR_URL$ISO_FILE_URI$ISO_MIRROR_FILE
else
    echo "INFO: input ISO already found in $HOME_DIR/$ISO_INPUT_DIR/"
	echo "------------------------------------------------------------"
fi


# Create directories if missing
if [ ! -d "$HOME_DIR/$ISO_MOUNT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_MOUNT_DIR
fi

if [ ! -d "$HOME_DIR/$ISO_EXTRACT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_EXTRACT_DIR
fi

if [ ! -d "$HOME_DIR/$ISO_OUTPUT_DIR" ]; then
	mkdir $HOME_DIR/$ISO_OUTPUT_DIR
fi

if [ ! -d "$HOME_DIR/$CUSTOM_PACKAGES" ]; then
	mkdir $HOME_DIR/$CUSTOM_PACKAGES
fi


# Get the OS to determine package manager, and install dependencies
echo "Determining OS and downloading required binaries"
echo "------------------------------------------------------------"

CURRENT_OS=$(awk -F= '/^NAME/{print tolower($2)}' /etc/os-release)
CURRENT_MAJOR=$(awk -F= '/^VERSION_ID/{print tolower($2)}' /etc/os-release)

case $CURRENT_OS in
	*"centos"* | *"fedora"* | *"red hat"*)
		# Download required packages for ISO generation
		yum -y -q install wget genisoimage python3 pykickstart createrepo >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
		# Download required extras if Centos 7
		if [ $CURRENT_MAJOR=7 ]; then
			# install and reinstall subcommand has to be used in case source system has one of the packages installed
			yum --downloadonly --downloaddir=$HOME_DIR/$CUSTOM_PACKAGES/ install hyperv-daemons open-vm-tools wget nano aide tcp_wrappers >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
			yum --downloadonly --downloaddir=$HOME_DIR/$CUSTOM_PACKAGES/ reinstall hyperv-daemons open-vm-tools wget nano aide tcp_wrappers >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
		else
			# Download the packages for the distro selected
			for reqpackage in $HOME_DIR/$CONFIG_INPUT_DIR/requirements.txt; do
				wget -q -O $HOME_DIR/$CUSTOM_PACKAGES/$reqpackage $ISO_MIRROR_URL$ISO_PACKS_URI$reqpackage
			done
		fi
	;;
	# TODO: Not tested, code implemented to help with generating ISO
	*"debian"* | *"ubuntu"*)
		apt-get -q install genisoimage python3 pykickstart createrepo >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
		# Download the packages for the distro selected
		for reqpackage in $HOME_DIR/$CONFIG_INPUT_DIR/requirements.txt; do
			wget -q -O $HOME_DIR/$CUSTOM_PACKAGES/$reqpackage $ISO_MIRROR_URL$ISO_PACKS_URI$reqpackage
		done
	;;
	# TODO: Not tested, code implemented to help with generating ISO
	*"suse"* | *"sles"*)
		zypper install -y genisoimage python3 pykickstart createrepo >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
		# Download the packages for the distro selected
		for reqpackage in $HOME_DIR/$CONFIG_INPUT_DIR/requirements.txt; do
			wget -q -O $HOME_DIR/$CUSTOM_PACKAGES/$reqpackage $ISO_MIRROR_URL$ISO_PACKS_URI$reqpackage
		done
	;;
	*)
		echo -n "Unknown OS to determine package manager"
	;;
esac


# Mount ISO and extract its contents with all files including hidden ones
echo "Mounting ISO file and copying content to temporary directory"
echo "------------------------------------------------------------"

INPUT_ISO_FILE=$(find $HOME_DIR/$ISO_INPUT_DIR -name '*.iso' -exec echo {} \;)
mount -t iso9660 -o loop $INPUT_ISO_FILE $HOME_DIR/$ISO_MOUNT_DIR/ >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
cp -arf $HOME_DIR/$ISO_MOUNT_DIR/* $HOME_DIR/$ISO_EXTRACT_DIR/
umount $HOME_DIR/$ISO_MOUNT_DIR/

# Fix for cases where the isolinux files are not allowed to be replaced
chmod 777 -R $HOME_DIR/$ISO_EXTRACT_DIR/

echo "ISO has been dismounted"
echo "------------------------------------------------------------"


# If the cp alias exists, remove the -i most systems aliases in the bash profile, and later reactivate
if alias cp 2>/dev/null; then
	unalias cp
	ALIAS_EXISTED="1"
fi


# Verify the kickstart file
echo "Verifying kickstart file"
echo "------------------------------------------------------------"
if [[ $(ksvalidator $HOME_DIR/$CONFIG_INPUT_DIR/ks.cfg) = *error* ]] ; then
	echo "Error in kickstart file validation, validate your file with ksvalidator"
	echo "------------------------------------------------------------"
	exit 1
fi
if [[ $(ksvalidator $HOME_DIR/$CONFIG_INPUT_DIR/ks.cfg) = *deprecated* ]] ; then
	echo "Deprecated command in kickstart file validation, validate your file with ksvalidator"
	echo "------------------------------------------------------------"
	exit 1
fi


# Copy customized files into the respective folder
echo "Copying customized files to temporary directory"
echo "------------------------------------------------------------"

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
	echo "Copying RPM files to ISO repository"
	echo "------------------------------------------------------------"

	# Copy custom packages from the extras folder to add to the ISO repository if there are any
	cp $HOME_DIR/$CUSTOM_PACKAGES/*.rpm $HOME_DIR/$ISO_EXTRACT_DIR/Packages/ >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

	echo "Rebuilding repository metadata"
	echo "------------------------------------------------------------"

	# Update the ISO yum repository with the added packages
	for repofile in $HOME_DIR/$ISO_EXTRACT_DIR/repodata/*minimal*comps.xml; do
		createrepo -g $repofile $HOME_DIR/$ISO_EXTRACT_DIR/ --update >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
	done
fi


# Create the custom scripts folder before ISO creation
if [ ! -d "$HOME_DIR/$ISO_EXTRACT_DIR/scripts" ]; then
	mkdir $HOME_DIR/$ISO_EXTRACT_DIR/scripts
fi


# Copy the customization service and script to the ISO extract folder
cp $HOME_DIR/$CONFIG_INPUT_DIR/bootstrap_install.service $HOME_DIR/$ISO_EXTRACT_DIR/scripts >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
cp $HOME_DIR/$CONFIG_INPUT_DIR/post_installation.sh $HOME_DIR/$ISO_EXTRACT_DIR/scripts >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1


# Set hostname on first boot if variable length is greater than 1
if [ ${#SYSTEM_FQDN_HOSTNAME} -ge 1 ]; then
	echo "hostname $SYSTEM_FQDN_HOSTNAME" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
fi

case $TEMPLATE in
	"msazsentinel")
		# TODO: MS AZ Sentinel CEF configuration Script doesn't support a proxy as the OMS agent installation does,
		# TODO: This asumes the box has direct internet connectivity.
		# TODO: The sysadmin user can change the OMS agent proxy configuration later on.
		if [ ${#AZ_WORKSPACE_ID} -ge 10 ] && [ ${#AZ_SHARED_KEY} -ge 10 ] && [ ${#SYSTEM_FQDN_HOSTNAME} -ge 1 ]; then
			# Add the CEF Agent configuration and OMS Agent installation to the first init script
			echo "wget https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/CEF/cef_installer.py&&python cef_installer.py $AZ_WORKSPACE_ID $AZ_SHARED_KEY" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
			# Add the OMS Agent service to the firewall
			echo "firewall-cmd --permanent --add-service=omsagent-$AZ_WORKSPACE_ID" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
			echo "firewall-cmd --reload" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
			# Disable first init service after finishing and remove script with data
			echo "systemctl disable bootstrap_install" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
			echo 'rm -- "$0" '>> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
		else
			echo "Azure Workspace ID, Shared Key or hostname are wrongly set"
			echo "------------------------------------------------------------"
			echo "Check your MS Azure variables and try again"
			echo "------------------------------------------------------------"
			# Remove extracted data
			rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*

			# Restore alias if existed
			if [ "$ALIAS_EXISTED"="1" ]; then
				alias cp='cp -i'
			fi

			exit 1
		fi
	;;
	*)
		# Disable first init service after finishing and remove script with data
		echo "systemctl disable bootstrap_install" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
		echo 'rm -- "$0" '>> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

		echo "Default customization files copied"
		echo "------------------------------------------------------------"
	;;
esac


# Restore alias if existed
if [ "$ALIAS_EXISTED"="1" ]; then
	alias cp='cp -i'
fi


# Create the ISO and remove the extracted files
echo "Creating ISO File"
echo "------------------------------------------------------------"

genisoimage -r -T -J -V "OEMDRV" -input-charset utf-8 -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -R -J -o $HOME_DIR/$ISO_OUTPUT_DIR/$ISO_OUTPUT_NAME $HOME_DIR/$ISO_EXTRACT_DIR >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

ISO_OUTPUT_FILE=$(find $HOME_DIR/$ISO_OUTPUT_DIR -name $ISO_OUTPUT_NAME -exec echo {} \;)


# Check if ISO exists
if [ -z "$ISO_OUTPUT_FILE" ]; then
    echo "Failed to create ISO file, check the logs"
	echo "------------------------------------------------------------"
else
    echo "ISO successfully created in $HOME_DIR/$ISO_OUTPUT_DIR/"
	echo "------------------------------------------------------------"
fi


# Remove extracted data
rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*