# Enable file integrity monitoring
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
echo "/usr/sbin/aide --check" >> /etc/cron.daily/aide_check.sh

# Ensure root ownership on the grub bootloader
chown root:root /boot/grub2/grub.cfg
chmod og-rwx /boot/grub2/grub.cfg
chown root:root /boot/grub2/user.cfg
chmod og-rwx /boot/grub2/user.cfg

# Ensure core dumps are restricted
echo "hard core 0" >> /etc/security/limits.d/CIS.conf
echo "fs.suid_dumpable = 0" >> /etc/sysctl.d/CIS.conf
sysctl -w fs.suid_dumpable=0

# Disable IPv6 at boot even if ignored in NetworkManager and enable audit
sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& ipv6.disable=1 audit=1/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Add privileged commands to auditing
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit -F path=" $1 " -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged" }' >> /etc/audit/rules.d/audit.rules
service auditd restart

# Ensure that unused file systems are removed (vfat is used by EFI)
echo "install udf /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf
echo "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf
rmmod squashfs
rmmod udf
rmmod cramfs

# Remove floppy as it is not needed
echo "blacklist floppy" >> /etc/modprobe.d/blacklist-floppy.conf
rmmod floppy

# Disable IPv6 settings not used
echo net.ipv6.conf.all.accept_redirects = 0>/etc/sysctl.d/CIS.conf
echo net.ipv6.conf.default.accept_redirects = 0>/etc/sysctl.d/CIS.conf
echo net.ipv6.conf.all.accept_ra = 0>/etc/sysctl.d/CIS.conf
echo net.ipv6.conf.default.accept_ra = 0>/etc/sysctl.d/CIS.conf
sysctl -w net.ipv6.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.default.accept_redirects=0
sysctl -w net.ipv6.conf.all.accept_ra=0
sysctl -w net.ipv6.conf.default.accept_ra=0
sysctl -w net.ipv4.route.flush=1

# Set cron ownership
chown root:root /etc/crontab
chmod 600 /etc/crontab
chown root:root /etc/cron.hourly
chmod 700 /etc/cron.hourly
chown root:root /etc/cron.daily
chmod 700 /etc/cron.daily
chown root:root /etc/cron.weekly
chmod 700 /etc/cron.weekly
chown root:root /etc/cron.monthly
chmod 700 /etc/cron.monthly
chown root:root /etc/cron.d
chmod 700 /etc/cron.d

# Ensure cron.deny doesnt exist and set cron.allow ownership
rm /etc/cron.deny
rm /etc/at.deny
touch /etc/cron.allow
chown root:root /etc/cron.allow
chmod 600 /etc/cron.allow
chown root:root /etc/at.allow
touch /etc/at.allow
chmod 600 /etc/at.allow

# Set the syslog-ng settings even if not used
if [[ ! -d /etc/syslog-ng ]]; then
        mkdir /etc/syslog-ng
fi
echo "options { chain_hostnames(off); flush_lines(0); perm(0640); stats_freq(3600); threaded(yes); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_console); destination(console); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_console); destination(xconsole); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_newscrit); destination(newscrit); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_newserr); destination(newserr); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_newsnotice); destination(newsnotice); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_mailinfo); destination(mailinfo); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_mailwarn); destination(mailwarn); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_mailerr); destination(mailerr); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_mail); destination(mail); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_acpid); destination(acpid); flags(final); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_acpid_full); destination(devnull); flags(final); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_acpid_old); destination(acpid); flags(final); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_netmgm); destination(netmgm); flags(final); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_local); destination(localmessages); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_messages); destination(messages); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_iptables); destination(firewall); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); source(chroots); filter(f_warn); destination(warn); };" >> /etc/syslog-ng/syslog-ng.conf

# Even if iptables is not used, add listening ports to allow rules
for port in $(netstat -lnt |grep ^tcp | grep LISTEN | awk {'print $4'} | cut -d":" -f2); do
       iptables -A INPUT -p tcp --dport $port -m state --state NEW -j ACCEPT
done
for port in $(netstat -lnt |grep ^udp | grep LISTEN | awk {'print $4'} | cut -d":" -f2); do
       iptables -A INPUT -p udp --dport $port -m state --state NEW -j ACCEPT
done

# Add port 22 (SSH) as this script happens before sshd starts
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# Set log files permissions (some will change later on, might have to cron this)
find /var/log -type f -exec chmod g-wx,o-rwx {} +

# Remove anaconda-ks files to reduce exposure of set passwords and settings on install
rm -f /root/original-ks.cfg
rm -f /root/anaconda-ks.cfg

# Set min and max password age for the already created users
chage --maxdays 90 sysadmin
chage --maxdays 90 netadmin
chage --mindays 7 sysadmin
chage --mindays 7 netadmin
