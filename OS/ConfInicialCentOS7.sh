#!/bin/bash
#-------------------------------------------------------------------------
# ConfInicialCentOS7
#
# Site  : http://www.douglas.wiki.br
# Author : Douglas Q. dos Santos <douglas.q.santos@gmail.com>
# Management: Douglas Q. dos Santos <douglas.q.santos@gmail.com>
#
#-------------------------------------------------------------------------
# Note: This Shell Script set up the initial configuration to CentOS 7
# where install the needed packets and configure some packets
#-------------------------------------------------------------------------
# History:
#
# Version 1:
# Data: 08/07/2014
# Description: Set up the initial configuration of CentOS 7 GNU/Linux
# set up the repositories and install some packets
#
#--------------------------------------------------------------------------
#License: http://creativecommons.org/licenses/by-sa/3.0/legalcode
#
#--------------------------------------------------------------------------
clear

#Set the colors used on the script
GREY="\033[01;30m" RED="\033[01;31m" GREEN="\033[01;32m" YELLOW="\033[01;33m"
BLUE="\033[01;34m" PURPLE="\033[01;35m" CYAN="\033[01;36m" WHITE="\033[01;37m"
CLOSE="\033[m"

#Validating who is going to execute the script
USU=$(whoami)

if [ "${USU}" != root ]; then
  echo
  echo -e "${RED}###################################################################################"
  echo -e " This script need to be execute with root user"
  echo -e " Exit..."
  echo -e "####################################################################################${CLOSE}"
  echo
  exit 1
fi


echo -e  "${RED}####################################################################${CLOSE}"
echo -e "${RED} This script is executing with the follow PID: ${GREEN} $$ ${CLOSE}   ${CLOSE}"
echo -e  "${RED}####################################################################${CLOSE}"
sleep 3

# Commands used on the Script
CAT="/bin/cat"
YUM="/usr/bin/yum"
RPM="/bin/rpm"
CHKCONFIG="/sbin/chkconfig"
CRONTAB="/usr/bin/crontab"
CP="/bin/cp"
RM="/bin/rm"
NTPDATE="/usr/sbin/ntpdate"
REBOOT="/sbin/reboot"
WGET="/usr/bin/wget"
MKDIR="/bin/mkdir"
SED="/bin/sed"
CD="cd"
GIT="/usr/bin/git"
CHSH="/usr/bin/chsh"
DOS2UNIX="/usr/bin/dos2unix"
SYSTEMCTL="/usr/bin/systemctl"
MACHINE="centos7"
DOMAIN="douglas.wiki.br"
IP=$(hostname -I)
RPM_FORGE="http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el7.rf.$(uname -i).rpm"

# The Follow packets going to be removed from the system
#REMOVABLE_PACKETS="dhcp3-client dhcp3-common nfs-common"
INSTALL_DEPENDS="wget yum-plugin-fastestmirror openssh-clients openssh-server net-tools deltarpm drpmsync epel-release"
INSTALL_PACKETS="vim-enhanced zip unzip unrar rar p7zip bzip2 less links telnet rsync kernel-headers ntpdate postfix cmake sudo git nmap tcpdump ncurses-devel dos2unix tofrodos bind-utils perl-core"
TOOLS="tcpstat ifstat dstat pciutils dmidecode htop usbutils strace ltrace hdparm sdparm iotop iotop iftop powertop zsh xz bc arp-scan sysstat libaio nc"
#PLUS_TOOLS="mytop dnstop vnstat"

# Set up the repository CentOS-Base
${SED} -i "s/enabled=0/enabled=1/" /etc/yum.repos.d/CentOS-Base.repo

# Checking the updates on the repository
${YUM} check-update

# Update the system
${YUM} update -y

# Installing the depends to configure to the system
${YUM} install ${INSTALL_DEPENDS} -y

# Installing the repository rpmforge
${RPM} -Uvh ${RPM_FORGE}

#Amending rpm force repository
${SED} -i 's/mirrorlist = http/#mirrorlist = http/g' /etc/yum.repos.d/rpmforge.repo
${SED} -i 's/#mirrorlist = file/mirrorlist = file/g' /etc/yum.repos.d/rpmforge.repo

# Checking the updates on the repository
${YUM} check-update

# Update the system
${YUM} update -y

# Installing the packets
${YUM} install ${INSTALL_PACKETS} -y
${YUM} install ${TOOLS} -y

# Installing Development Tools
${YUM} group install "Development Tools" -y
${YUM} update -y

# Disabling the firewall
${SYSTEMCTL} stop firewalld.service
${SYSTEMCTL} disable firewalld.service

# Disabling the selinux
${CP} -Rfa /etc/sysconfig/selinux{,.bkp}
${CAT} << EOF > /etc/sysconfig/selinux
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#enforcing - SELinux security policy is enforced.
#permissive - SELinux prints warnings instead of enforcing.
#disabled - SELinux is fully disabled.
SELINUX=disabled    # change
# SELINUXTYPE= type of policy in use. Possible values are:
#targeted - Only targeted network daemons are protected.
#strict - Full SELinux protection.
SELINUXTYPE=targeted
EOF

# Set up the hostname for the machine
#${SED} -i "s/HOSTNAME=localhost.localdomain/HOSTNAME=${MACHINE}/" /etc/sysconfig/network
echo "${MACHINE}" > /etc/hostname
echo "${IP}  ${MACHINE}.${DOMAIN}  ${MACHINE}" >> /etc/hosts

# Download the configuration file to VIM
${WGET} -c http://www.douglas.wiki.br/Downloads/scripts/.vimrc -O /root/.vimrc

#Convert the file to Unix format
${DOS2UNIX} /root/.vimrc

# Clear the terminal on the logout
echo "clear" > .bash_logout

# Will be set up the bashrc with a new configuration
${CAT} << EOF > /root/.bashrc
# .bashrc
    PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '

    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'

export EDITOR=vim
export HISTTIMEFORMAT="%h/%d - %H:%M:%S "
TZ='America/Sao_Paulo'; export TZ


# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

mesg y
EOF

# Will be set up the bashrc with a new configuration to new users
${CAT} << EOF > /etc/skel/.bashrc
# .bashrc


    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '

    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'

export EDITOR=vim
export HISTTIMEFORMAT="%h/%d - %H:%M:%S "
TZ='America/Sao_Paulo'; export TZ

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

mesg y
EOF

# Making the backup to bashrc
${CP} /root/.bashrc /root/.bashrc.old


# Set up the Crontab
CRON=/tmp/cron

# Tasks scheduled on the Cron
${CAT} << EOF > ${CRON}
# Minute Hour Day Month Day_of_the_Week User Command
#
# Minute - You can use the follow (0-59)
# Hour - You can use the follow (0-23)
# Day - You can use the follow (1-31)
# Month - You can use the follow (1-12)
# Day_of_the_Week - Day of the Week. (0-7; note.: 0 and 7 are Sunday).
# Use - This is optional, you can define the user that run the job
# Command - Command is the job that will be execute on the specified time
# i.e: For to Schedule a task to execute each 8 hours: * */8 * * * user /path/to/task
#
0 */8      *       *       *       /usr/bin/yum check-update
0 */6      *       *       *       /usr/sbin/ntpdate -u a.ntp.br
0 */12     *       *       *       /usr/bin/updatedb
EOF

# Remove the current crontab
${CRONTAB} -r

# For to Schedule the new crontab
${CRONTAB} ${CRON}

# Removing the temp crontab
${RM} -rf ${CRON}

# To doing the downloading the last version of the Kernel firmware
${CD} /usr/src
${GIT} clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git firmware
${CP} -Rfa firmware/* /lib/firmware/

#Set the default shell with fish shell
#if [ $(uname -m) == "x86_64" ]; then
#${WGET} -c http://www.douglas.wiki.br/Downloads/misc/fish-2.1.0-2.1.x86_64.rpm -O /tmp/fish-2.1.0-2.1.x86_64.rpm
#${RPM} -ivh /tmp/fish-2.1.0-2.1.x86_64.rpm
#else
#${WGET} -c http://www.douglas.wiki.br/Downloads/misc/fish-2.1.0-2.1.i386.rpm -O /tmp/fish-2.1.0-2.1.i386.rpm
#${RPM} -ivh /tmp/fish-2.1.0-2.1.i386.rpm
#fi

#CHANGING DEFAULT SHELL FOR ROOT
#${CHSH} -s /usr/bin/fish
#echo "set -x EDITOR vim" >> /etc/fish/config.fish

# Rebooting the system for read all news configurations
${REBOOT}
