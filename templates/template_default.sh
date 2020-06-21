# Disable service after first start
echo "systemctl disable bootstrap_install" >> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh

# Remove this script as part of system cleanup
echo 'rm -- "$0" '>> $HOME_DIR/$ISO_EXTRACT_DIR/scripts/post_installation.sh