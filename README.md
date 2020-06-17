# BlackBox Appliance
![BlackBox Appliance Logo](https://github.com/cristianhares/blackbox_appliance/blob/master/images/small_logo.png?raw=true)

------------------------------------------------------------------
**Description**<br/>
A Linux-based automatic installation multi-purpose closed-up hardened appliance.<br/>
<br/>
If you found it useful and if you can, consider buying me a coffee :) https://buymeacoff.ee/cristianhares<br/>
<br/>
Small History: Over my years working with SIEMs and other vendor's apppliances, I was always surprised by the fact there wasn't an open source appliance that would make the same experience of a closed-up box where you could run your own application, so I had this idea sitting there for quite some time. An example of this was a cheap Syslog collector with store-and-forward capabilities without paying for the crazy licensing fees of a vendor collector.<br/>
<br/>
**Current State**:<br/>
The BlackBox appliance right now is based on Centos7 and should work with RHEL 7/8 and Centos 8, still most Enterprise tech supports major version 7.<br/>
<br/>
The system has 3 users, the root (disabled), the sysadmin (with sudo privs) which the "Service Provider" controls, and the netadmin which the "customer" controls and can only set networking parameters.<br/>
<br/>
So the idea is basically that you ("the Service Provider") provide your "customer" with a plug-and-play system, where they don't have to do anything, and you can add a command and control channel to call home or talk to a central server if needed.<br/>
<br/>
Note: the current state is a working PoC, so most likely still has bugs/missing things that I haven't found yet.<br/>
<br/>
This solution will use Centos 7 minimal as a base, Centos 8 no longer has minimal but it should work editing the code (line 156, *comps.xml) to detect the repository metadata you want to use.<br/>
<br/>
There's this great project for a Centos 8 minimal that's worthy to look at: https://github.com/uboreas/centos-8-minimal<br/>
<br/>
Since Ubuntu allows kickstart it can be made to work as the source distro, but the code is not ready yet to handle the way ubuntu manages it repositories.<br/>
<br/>
**PS:** I know the logo is a bit ugly, is the best I could come up with with Paint3D :P.<br/>
<br/>
**Some ideas**<br/>
Some of the following ideas I'll try to deploy them as "templates" in the future.<br/>
<br/>
&nbsp;&nbsp;- Syslog collector to forward events to a central log system.<br/>
&nbsp;&nbsp;- Docker node and manage it remotely with swarm.<br/>
&nbsp;&nbsp;- Add openvpn or any vpn software with certificate auth to talk back securely to your network.<br/>
&nbsp;&nbsp;- Network scanner with nmap or any other scanning library.<br/>
&nbsp;&nbsp;- Software remote deployer (relay) for windows/linux systems.<br/>
<br/>
**Current functionality**<br/>
&nbsp;&nbsp;- Create an automated ISO image depending on parameters set in main script.<br/>
&nbsp;&nbsp;- Automatic installation of system with almost no user interaction.<br/>
&nbsp;&nbsp;- System is divided by a privileged user and a non-privileged user that can only change networking.<br/>
&nbsp;&nbsp;- Run commands/installations after first boot via the post_installation.sh script.<br/>
&nbsp;&nbsp;- Automatic installation of VM Hypervisor tools depending on platform.<br/>
&nbsp;&nbsp;- Add to the ISO repo extra packages of your choosing.<br/>
&nbsp;&nbsp;- Check with ksvalidator if the ks.cfg is valid prior to ISO creation.<br/>
&nbsp;&nbsp;- Hash and salt the passwords using SHA512.<br/>
&nbsp;&nbsp;- Microsoft Azure Sentinel CEF rsyslog collector with OMS Agent template.<br/>

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
<br/>
**Note:** The reason behind not including them with the code is because of all the licensing mumbo jumbo legalese jargon.<br/>
<br/>
**WARNING:** If you download this code through Windows GIT for using it with WSL, remember that it changes the LF to CRLF in the sh file.<br/>
<br/>

------------------------------------------------------------------
**Instructions for ISO generation**<br/>
(Optional, the script will do it for you if needed) Download the Centos7 minimal ISO of the minor version of your choosing and put it in the ISO_INPUT_DIR folder defined in the script (default: iso_input).<br/>
<br/>
Do NOT forget to edit your environment parameters at the start of the main script (create_blackbox_iso.sh).<br/>
<br/>
Edit the CONFIG_INPUT_DIR/requirements.txt according to the System Distro version you want to use.<br/>
<br/>
You can edit the CONFIG_INPUT_DIR/post_installation.sh for the commands to run after first boot and the network adapter starts.<br/>
<br/>
**usage:** ./create_blackbox_iso.sh [OPTIONS]<br/>
<br/>
optional arguments:<br/>
&nbsp;&nbsp;-d --default&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;default ISO creation process.<br/>
&nbsp;&nbsp;-azs, --azuresentinel&nbsp;&nbsp;&nbsp;ISO with Azure Sentinel CEF collector & OMS Agent.<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Note: requires the workspace ID, shared key and system hostname set in main script.<br/>
&nbsp;&nbsp;-? | -h | --help&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;shows this usage text.<br/>
<br/>

------------------------------------------------------------------
**Known issues / Planned development**<br/>
&nbsp;&nbsp;- Trying to replace python2 with python3 as part of %packages is not liked by anaconda/kickstart.<br/>
&nbsp;&nbsp;- Debian and Suse based distros for the ISO creation may not have the required packages to run the script.<br/>
&nbsp;&nbsp;- Missing some error control scenarios, like detecting if the ISO is file-locked before saving.<br/>
&nbsp;&nbsp;- ISO generation script is not proxy-aware.<br/>