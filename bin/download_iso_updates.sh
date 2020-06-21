#!/bin/bash
# Download ISO updates for specific ISO release for yum-based systems
# Author: Cristian H. Ares (https://www.linkedin.com/in/cares/)

# Add the package updates in the disk in accordance to version
touch /etc/yum.repos.d/localiso.repo
echo "[LocalISO]" >> /etc/yum.repos.d/localiso.repo
echo "name=Local Updates" >> /etc/yum.repos.d/localiso.repo
echo "baseurl=file://$HOME_DIR/$ISO_EXTRACT_DIR/" >> /etc/yum.repos.d/localiso.repo
echo "enabled=1" >> /etc/yum.repos.d/localiso.repo
echo "gpgkey=file://$HOME_DIR/$ISO_EXTRACT_DIR/$ISO_GPG_KEY" >> /etc/yum.repos.d/localiso.repo

# Add the update repo for the specific version of the distro
touch /etc/yum.repos.d/releaseupdates.repo
echo "[ReleaseUpdates]" >> /etc/yum.repos.d/releaseupdates.repo
echo "name=Release Updates" >> /etc/yum.repos.d/releaseupdates.repo
echo "baseurl=http://mirror.centos.org/centos/$ISO_RELEASE$ISO_UPDATES_URI" >> /etc/yum.repos.d/releaseupdates.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/releaseupdates.repo
echo "gpgkey=file://$HOME_DIR/$ISO_EXTRACT_DIR/$ISO_GPG_KEY" >> /etc/yum.repos.d/releaseupdates.repo

# cleanup to recognize new repos
yum clean all >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

# find the missing updates for the ISO repo
ISO_PACKAGES=$(repoquery --repoid=LocalISO -a | sed -r 's/-[0-9]+\:.*$//')
UPDATED_PACKAGES=$(repoquery --repoid=ReleaseUpdates -a | sed -r 's/-[0-9]+\:.*$//')
ISO_UPDATES=$(comm -1 -2 <(echo "$ISO_PACKAGES" | sort) <(echo "$UPDATED_PACKAGES" | sort))

yum -y --disablerepo="*" --enablerepo="LocalISO,ReleaseUpdates" --skip-broken --downloadonly --downloaddir=$HOME_DIR/$ISO_EXTRACT_DIR/Packages install $ISO_UPDATES >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
yum -y --disablerepo="*" --enablerepo="LocalISO,ReleaseUpdates" --skip-broken --downloadonly --downloaddir=$HOME_DIR/$ISO_EXTRACT_DIR/Packages reinstall $ISO_UPDATES >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1
yum -y --disablerepo="*" --enablerepo="LocalISO,ReleaseUpdates" --skip-broken --downloadonly --downloaddir=$HOME_DIR/$ISO_EXTRACT_DIR/Packages update $ISO_UPDATES >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1

# Remove custom repos after finishing download
rm -f /etc/yum.repos.d/localiso.repo
rm -f /etc/yum.repos.d/releaseupdates.repo
rm -rf /var/cache/yum
yum clean all >> $HOME_DIR/$LOG_FILE_DIR/$LOG_FILE_NAME 2>&1