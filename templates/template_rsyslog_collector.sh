# Disable service after first start
echo "systemctl disable bootstrap_install" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Enable listening for syslog in UDP 514 and TLS syslog in TCP 6514
echo "firewall-cmd --permanent --add-service=syslog" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "firewall-cmd --permanent --add-service=syslog-tls" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "firewall-cmd --reload" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Enable listening in UDP 514, TCP 6514
echo "sed -i '/\$ModLoad imudp/s/^#//g' /etc/rsyslog.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "sed -i '/\$UDPServerRun/s/^#//g' /etc/rsyslog.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "sed -i '/\$ModLoad imtcp/s/^#//g' /etc/rsyslog.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
echo "sed -i '/InputTCPServerRun/c\$InputTCPServerRun 6514' /etc/rsyslog.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Set syslog destination
echo "sed -i '/remote-host/s/^#//g' /etc/rsyslog.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# If the destination is TCP, ensure reliability by setting a cache
if [[ $SYSLOG_DESTINATION_PROTOCOL == "TCP" ]]; then
    echo "sed -i \"/remote-host/c\\\\\\x2A\\x2E\\x2A \\x40\\x40$SYSLOG_DESTINATION:$SYSLOG_DESTINATION_PORT\" /etc/rsyslog.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

    # Create caching directory
    echo "if [ ! -e \"$SYSLOG_CACHE_DIR\" ]; then" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "    mkdir $SYSLOG_CACHE_DIR" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "    chmod 600 $SYSLOG_CACHE_DIR" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "fi" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

    # Set caching parameters to ensure saving logs if destination is unreacheable (TCP)
    echo "echo \"\$WorkDirectory $SYSLOG_CACHE_DIR\" > /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "echo \"\$ActionQueueType LinkedList\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "echo \"\$ActionQueueFileName forward_destination1\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "echo \"\$ActionQueueMaxDiskSpace $SYSLOG_CACHE_SIZE\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "echo \"\$ActionResumeRetryCount -1\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    echo "echo \"\$ActionQueueSaveOnShutdown on\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

    if [[ $SYSLOG_DESTINATION_TLS == "YES" ]]; then
        # Set a non-authenticated config for TLS Syslog
        echo "echo \"\$DefaultNetstreamDriverCAFile $SYSLOG_TRUST_CERTS\" > /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
        echo "echo \"\$DefaultNetstreamDriver gtls\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
        echo "echo \"\$ActionSendStreamDriverMode 1\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
        echo "echo \"\$InputTCPServerStreamDriverAuthMode anon\" >> /etc/rsyslog.d/90-cachesettings.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
    fi
else
    # Remove one @ (\x40) to set UDP destination
    echo "sed -i \"/remote-host/c\\\\\x2A\\x2E\\x2A \\x40$SYSLOG_DESTINATION:$SYSLOG_DESTINATION_PORT\" /etc/rsyslog.conf" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
fi

# Restart the syslog daemon
echo "systemctl restart rsyslog" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Remove this script as part of system cleanup
echo 'rm -- "$0" '>> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh
