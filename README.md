# BlackBox Appliance
![BlackBox Appliance Logo](https://github.com/cristianhares/blackbox_appliance/blob/master/images/small_logo.png?raw=true)

------------------------------------------------------------------
**Description**<br/>
A Linux-based automatic installation multi-purpose closed-up hardened appliance.<br/>
<br/>
If you found it useful and if you can, consider buying me a coffee :) https://buymeacoff.ee/cristianhares or https://ko-fi.com/cristianhares<br/>
<br/>
Small History: Over my years working with SIEMs and other vendor's appliances, I was always surprised by the fact there wasn't an open source appliance that would make the same experience of a closed-up box where you could run your own application, so I had this idea sitting there for quite some time. An example of this was a cheap Syslog collector with store-and-forward capabilities without paying for the crazy licensing fees of a vendor collector.<br/>
<br/>
**Current State**:<br/>
The BlackBox appliance right now is based on Centos7 and should work with RHEL 7/8 and Centos 8, still most Enterprise tech supports major version 7.<br/>
<br/>
The system has 3 users, the root (disabled), the sysadmin (with sudo privs) and the netadmin which can only set networking parameters. An example usage of this would be of a "Service Provider" that maintains control of the box, and its "customer" can only change network parameters.<br/>
<br/>
So the idea is basically that you ("the Service Provider") provide your "customer" with a plug-and-play system, where they don't have to do anything, and you can add a command and control channel to call home or talk to a central server if needed.<br/>
<br/>
Note: System has been hardened in accordance to most of the checks of the CIS Benchmark, even so it is likely it still has bugs/missing things that I haven't found yet.<br/>
<br/>
This solution will use Centos 7 minimal as a base, Centos 8 no longer has minimal but it should work editing the code (line 156, *comps.xml) to detect the repository metadata you want to use. There's this great project for a Centos 8 minimal that's worthy to look at for this case: https://github.com/uboreas/centos-8-minimal<br/>
<br/>
Since Ubuntu allows kickstart it can/could be made to work as the source distro, but the code is not ready yet to handle the way ubuntu manages it repositories.<br/>
<br/>
**Note:** If you download this code through Windows GIT for using it with WSL, remember that it changes the LF to CRLF in the sh file, so use the dos2unix program.<br/>
<br/>
**PS:** I know the logo is a bit ugly, is the best I could come up with with Paint3D :P.<br/>
<br/>

**ISO Creation features**<br/>
&nbsp;&nbsp;- Automatically downloads required packages for ISO generation depending on your OS distro.<br/>
&nbsp;&nbsp;- Automatically downloads ISO Linux distro.<br/>
&nbsp;&nbsp;- Automatically downloads updates since release for the chose distro and add them to the ISO repo (YUM based systems).<br/>
&nbsp;&nbsp;- Validates the ks.cfg config before creation.<br/>
&nbsp;&nbsp;- Add extra packages of your choosing by adding them in the extras directory.<br/>
&nbsp;&nbsp;- Add commands of your choosing either in the ks.cfg post section, or the post_installation.sh script.<br/>

**System Image features**<br/>
&nbsp;&nbsp;- Automatic System installation with auto partitioning, no user interaction (except for one enter!).<br/>
&nbsp;&nbsp;- Automatic installation of VM Hypervisor tools depending on platform.<br/>
&nbsp;&nbsp;- System has been hardened in accordance to most of the checks of the CIS Benchmark.<br/>
&nbsp;&nbsp;- Run commands/installations after first boot via the post_installation.sh script.<br/>
&nbsp;&nbsp;- System is divided by a privileged user and a non-privileged user that can only change networking (Good for Service Providers!).<br/>

**Available Templates**<br/>
&nbsp;&nbsp;- Default template: Build the BlackBox Appliance you want!.<br/>
&nbsp;&nbsp;- Microsoft Azure Sentinel CEF rsyslog collector with OMS Agent template.<br/>
&nbsp;&nbsp;- Syslog collector (with TCP support, local cache, and TLS support!).<br/>

------------------------------------------------------------------

**Planned Templates**<br/>
&nbsp;&nbsp;- Docker node for quickly setting up docker images.<br/>
&nbsp;&nbsp;- Quickly deployed secure web server with Availability functionality.<br/>
&nbsp;&nbsp;- Load balancer with transparent TCP proxy.<br/>

**Planned Functionality**<br/>
&nbsp;&nbsp;- Establish a control channel via VPN (OpenVPN) to a VPN Server for remote control (Good for Service Providers!).<br/>
&nbsp;&nbsp;- Network scanning with nmap for making network inventory available to SIEMs and other platforms.<br/>
&nbsp;&nbsp;- Powershell script that installs WSL so that you can create the ISO easily in Windows.<br/>
&nbsp;&nbsp;- Install Docker if needed in other Linux distros to get CentOS/RHEL for generating ISO.<br/>

**Not Planned Templates (Ideas)**<br/>
&nbsp;&nbsp;- IAM Platform.<br/>
&nbsp;&nbsp;- Directory Services Platform.<br/>
&nbsp;&nbsp;- RADIUS server with 2FA Support with Yubico.<br/>

------------------------------------------------------------------
**Package Requirements**<br/>
The scripts for the ISO generation are based to run on linux, in windows I use WSL for this, the main script will attempt to install and download them in your distro if available from the repos, although I know in newer ubuntu's some are not present, and I haven't tested it yet in Suse-based ones.<br/>
<br/>
Main Script (it will try to download them):<br/>
&nbsp;&nbsp;- genisoimage<br/>
&nbsp;&nbsp;- python3<br/>
&nbsp;&nbsp;- pykickstart<br/>
&nbsp;&nbsp;- createrepo<br/>
<br/>
Generated ISO (it will try to download them for Centos 7):<br/>
&nbsp;&nbsp;- open-vm-tools (and dependencies)<br/>
&nbsp;&nbsp;- hyperv-daemons (and dependencies)<br/>
&nbsp;&nbsp;- wget<br/>
&nbsp;&nbsp;- nano<br/>
&nbsp;&nbsp;- aide<br/>
&nbsp;&nbsp;- tcp_wrappers<br/>
<br/>
**Note:** The reason behind not including the package requirements with the code is because of all the licensing mumbo jumbo legalese jargon required to do so.<br/>
<br/>

------------------------------------------------------------------
**Instructions for ISO generation**<br/>
(Optional, the script will do it for you if needed) Download the Centos7 minimal ISO of the minor version of your choosing and put it in the ISO_INPUT_DIR folder defined in the script (default: iso_input).<br/>
<br/>
Do NOT forget to edit your environment parameters at the start of the main script (create_blackbox_iso.sh).<br/>
<br/>
You can add your custom packages in the extras folder and then add them in the %packages section of the ks.cfg file, or you can also add them to the PACKAGES_SYSTEM variable if you want them automatically downloaded if they are present in a YUM repository (you have to add the dependencies for the moment).<br/>
<br/>
If YUM is not available, edit the CONFIG_INPUT_DIR/requirements.txt according to the System Distro version you want to use for downloading them.<br/>
<br/>
You can edit the CONFIG_INPUT_DIR/post_installation.sh for the commands to run after first boot and the network adapter starts.<br/>
<br/>
**usage:** ./create_blackbox_iso.sh [OPTIONS]<br/>
<br/>
optional arguments:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;-d | --default&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;default ISO creation process.<br/>
&nbsp;&nbsp;-azs | --azuresentinel&nbsp;&nbsp;&nbsp;&nbsp;ISO with Azure Sentinel CEF collector & OMS Agent.<br/>
&nbsp;&nbsp;&nbsp;&nbsp;-s | --syslogcollector&nbsp;&nbsp;&nbsp;&nbsp;ISO with RSyslog syslog collector.<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Note: requires the workspace ID, shared key and system hostname set in main script.<br/>
&nbsp;&nbsp;&nbsp;&nbsp;-? | -h | --help&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;shows this usage text.<br/>
<br/>

------------------------------------------------------------------
**Known issues / Planned development**<br/>
&nbsp;&nbsp;- Still missing some error control scenarios.<br/>
&nbsp;&nbsp;- ISO generation script is not proxy-aware yet.<br/>
