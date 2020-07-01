# Add the required packages to the ks.cfg file
for package in $AZ_REQUIRED_PACKAGES; do
    sed -i "/^\x25include \x2ftmp\x2fvirtualmachine.*/i $package" $HOME_DIR/$ISO_EXTRACT_DIR/ks.cfg
done

# Disable service after first start
echo "systemctl disable bootstrap_install" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Add the CEF Agent configuration and OMS Agent installation to the first init script
echo "curl -o cef_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/CEF/cef_installer.py && python cef_installer.py $AZ_WORKSPACE_ID $AZ_SHARED_KEY" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Enable listening for syslog in UDP 514 and TLS syslog in TCP 6514
echo "firewall-cmd --permanent --add-service=syslog" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "firewall-cmd --permanent --add-service=syslog-tls" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "firewall-cmd --permanent --add-service=rsh" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "firewall-cmd --permanent --add-port=25226/tcp" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "firewall-cmd --reload" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Allow the MMA through SELinux
echo "semanage port -a -t syslogd_port_t -p tcp 25226" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Disable first init service after finishing and remove script with data
echo "systemctl disable bootstrap_install" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Remove this script as part of system cleanup
echo 'rm -- "$0" '>> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh