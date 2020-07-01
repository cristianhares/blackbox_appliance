#!/bin/bash
# Download ISO generation packages depending on OS distro
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

		# Required packages are in Centos/RHEL 6, 7 and 8, and in Fedora 30, 31, and 32
		if [[ "$CURRENT_MAJOR" == "6" || "$CURRENT_MAJOR" == "7" || "$CURRENT_MAJOR" == "8" || "$CURRENT_MAJOR" == "30" || "$CURRENT_MAJOR" == "31" || "$CURRENT_MAJOR" == "32" ]]; then

			# Download required packages for ISO generation
			yum -y -q install genisoimage python3 pykickstart createrepo yum-utils >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

			# Add the update repo for the specific version of the distro
			touch /etc/yum.repos.d/releasepackages.repo
			echo "[ReleasePackages]" >> /etc/yum.repos.d/releaseupdates.repo
			echo "name=Release Packages" >> /etc/yum.repos.d/releaseupdates.repo
			echo "baseurl=http://mirror.centos.org/centos/$ISO_RELEASE$ISO_PACKS_URI" >> /etc/yum.repos.d/releaseupdates.repo
			echo "gpgcheck=1" >> /etc/yum.repos.d/releaseupdates.repo
			echo "gpgkey=file://$HOME_DIR/$ISO_EXTRACT_DIR/$ISO_GPG_KEY" >> /etc/yum.repos.d/releaseupdates.repo

			# Cleanup to recognize new repos
			yum clean all >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

			# Add extra packages depending on template
			if [[ $TEMPLATE == "msazsentinel" ]]; then
				AZ_PACKAGES_DEPS=$(repoquery --requires --recursive --resolve --repoid=ReleasePackages -a $AZ_REQUIRED_PACKAGES | sed -r 's/-[0-9]+\:.*$//')
				PACKAGES_TO_DOWNLOAD="${PACKAGES_SYSTEM} ${AZ_REQUIRED_PACKAGES} ${AZ_PACKAGES_DEPS}"
			else
				PACKAGES_TO_DOWNLOAD=$PACKAGES_SYSTEM
			fi

			# Download required packages for system installation and its dependencies if missing
			yum -y --disablerepo="*" --enablerepo="ReleasePackages" --skip-broken --downloadonly --downloaddir=$HOME_DIR/$ISO_EXTRACT_DIR/Packages/ install $PACKAGES_TO_DOWNLOAD >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
			yum -y --disablerepo="*" --enablerepo="ReleasePackages" --skip-broken --downloadonly --downloaddir=$HOME_DIR/$ISO_EXTRACT_DIR/Packages/ reinstall $PACKAGES_TO_DOWNLOAD >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

			# Remove release repo after finishing download
			rm -f /etc/yum.repos.d/releaseupdates.repo
			rm -rf /var/cache/yum
			yum clean all >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
        else
			echo "ERROR: Centos/RHEL/Fedora distro used for generating ISO will not have the packages required"
			echo "----------------------------------------------------------------------"
            # Remove extracted data
            rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
            exit 1
        fi
	;;
	*"ubuntu"*)
		# Required packages are in Ubuntu 14.04 (Trusty Tahr), 16.04 (Xenial Xerus) and 18.04 (Bionic Beaver), but not in 20.04 (Focal Fossa)
		if [[ "$CURRENT_MAJOR" == "14.04" || "$CURRENT_MAJOR" == "16.04" || "$CURRENT_MAJOR" == "18.04" ]]; then
			apt-get update
			apt-get -q install genisoimage python3 python-pykickstart createrepo >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
			# Download the packages for the distro selected
			for reqpackage in $HOME_DIR/$CONFIG_INPUT_DIR/requirements.txt; do
				curl -so $HOME_DIR/$ISO_EXTRACT_DIR/Packages/$reqpackage $ISO_MIRROR_URL$ISO_RELEASE$ISO_PACKS_URI\Packages/$reqpackage
			done
		else
			echo "ERROR: Ubuntu distro used for generating ISO will not have the packages required"
			echo "----------------------------------------------------------------------"
            # Remove extracted data
            rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
            exit 1
		fi
	;;
	*"debian"*)
		# Required packages are in Debian 8 (jessie), 9 (stretch) and 10 (buster)
		if [[ "$CURRENT_MAJOR" == "8" || "$CURRENT_MAJOR" == "9" || "$CURRENT_MAJOR" == "10" ]]; then
			apt-get update
			apt-get -q install genisoimage python3 python-pykickstart createrepo >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
			# Download the packages for the distro selected
			for reqpackage in $HOME_DIR/$CONFIG_INPUT_DIR/requirements.txt; do
				curl -so $HOME_DIR/$ISO_EXTRACT_DIR/Packages/$reqpackage $ISO_MIRROR_URL$ISO_RELEASE$ISO_PACKS_URI\Packages/$reqpackage
			done
		else
			echo "ERROR: Ubuntu distro used for generating ISO will not have the packages required"
			echo "----------------------------------------------------------------------"
            # Remove extracted data
            rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
            exit 1
		fi
	;;
	*"suse"*) # Sles official repos dont include all the required tools
		if [[ $CURRENT_MAJOR="15.2" ]]; then
			zypper refresh

			# Suse and Sles uses mkisofs instead of genisoimage
			zypper install -y mkisofs python3 python-pykickstart createrepo >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

			# Download the packages for the distro selected
			for reqpackage in $HOME_DIR/$CONFIG_INPUT_DIR/requirements.txt; do
				curl -so $HOME_DIR/$ISO_EXTRACT_DIR/Packages/$reqpackage $ISO_MIRROR_URL$ISO_RELEASE$ISO_PACKS_URI$reqpackage
			done
		else
			echo "ERROR: Suse distro used for generating ISO will not have the packages required"
			echo "----------------------------------------------------------------------"
            # Remove extracted data
            rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
            exit 1
		fi
	;;
	*)
		echo "ERROR: Unknown OS Distro detected, finishing process"
		echo "----------------------------------------------------------------------"
        # Remove extracted data
        rm -rf $HOME_DIR/$ISO_EXTRACT_DIR/*
        exit 1
	;;
esac