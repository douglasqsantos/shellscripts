#!/bin/bash
#-------------------------------------------------------------------------
# ConfInicialWheezy
#
# Site  : http://www.douglasqsantos.com.br
# Author : Douglas Q. dos Santos <douglas.q.santos@gmail.com>
# Management: Douglas Q. dos Santos <douglas.q.santos@gmail.com>
#
#-------------------------------------------------------------------------
# Note: This Shell Script set up the initial configuration to Debian Wheezy
# where install the needed packets and configure some packets
#-------------------------------------------------------------------------
# History:
#
# Version 1:
# Data: 22/02/2011
# Description: Set up the initial configuration of Debian GNU/Linux Wheezy
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
APTGET="/usr/bin/apt-get"
APTITUDE="/usr/bin/aptitude"
CRONTAB="/usr/bin/crontab"
CP="/bin/cp"
RM="/bin/rm"
NTPDATE="/usr/sbin/ntpdate"
REBOOT="/sbin/reboot"
WGET="/usr/bin/wget"
GPG="/usr/bin/gpg"
APT_KEY="/usr/bin/apt-key"
MKDIR="/bin/mkdir"
SED="/bin/sed"
CD="cd"
GIT="/usr/bin/git"
CHSH="/usr/bin/chsh"
DOS2UNIX="/usr/bin/dos2unix"
APT="/etc/apt"
DPKG="/usr/bin/dpkg"

# The Follow packets going to be removed from the system
#REMOVABLE_PACKETS="dhcp3-client dhcp3-common nfs-common"
INSTALL_PACKETS="vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf rsync build-essential linux-headers-$(uname -r) libncurses5-dev ntpdate postfix cmake sudo git makepasswd"
TOOLS="atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm sdparm iotop atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan"
#PLUS_TOOLS="mytop ptop dnstop vnstat"


# Performing the sources.list backup
${CP} -Rf ${APT}/sources.list ${APT}/${APTBKP} 2> /dev/null

# Remaking the sources.lists configuration
${CAT} << EOF > ${APT}/sources.list
# Date of the file: $(date)
# Official repository
deb http://ftp.br.debian.org/debian wheezy main contrib non-free
deb-src http://ftp.br.debian.org/debian wheezy main contrib non-free


# Security update repository
deb http://security.debian.org/ wheezy/updates main contrib non-free
deb-src http://security.debian.org/ wheezy/updates main contrib non-free

# Propose update repository
deb http://ftp.br.debian.org/debian wheezy-proposed-updates main contrib non-free
deb-src http://ftp.br.debian.org/debian wheezy-proposed-updates main contrib non-free


# Backport repository
#deb http://ftp.br.debian.org/debian wheezy-backports main contrib non-free
#deb-src http://ftp.br.debian.org/debian wheezy-backports main contrib non-free


# Backport 2 repository
#deb http://www.backports.org/debian wheezy-backports main contrib non-free
#deb-src http://www.backports.org/debian wheezy-backports main contrib non-free

# Multimedia repository
#deb http://ftp.br.debian.org/debian-multimedia/ wheezy main
#deb http://www.debian-multimedia.org wheezy main

# PHP5 BACKPORT
#deb http://packages.dotdeb.org wheezy all
#deb-src http://packages.dotdeb.org wheezy all

#deb http://packages.dotdeb.org wheezy-php55 all
#deb-src http://packages.dotdeb.org wheezy-php55 all

# Repository for postfix-vda
#deb http://debian.home-dn.net/wheezy postfix-vda/
#deb-src http://debian.home-dn.net/wheezy postfix-vda/
EOF

#Updating debian priority and frontend
export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive

# Updating the repositories
${APTITUDE} -y update


# Updating the keys repositories (KEYRINGS)
${APTITUDE} -y install debian-archive-keyring
#${GPG} --keyserver pgp.uni-mainz.de --recv-keys 1F41B907
${GPG} --keyserver pgpkeys.mit.edu --recv-keys 1F41B907
#${GPG} --keyserver pgp.uni-mainz.de --recv-key A2098A6E
${GPG} --keyserver pgpkeys.mit.edu --recv-key A2098A6E
${APT_KEY} add ~root/.gnupg/pubring.gpg

### Changing the DEBCONF to CRITICAL, to install the packets without prompts questions ###
export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive

# Installing the packets
${APTITUDE} install ${INSTALL_PACKETS} -y
${APTITUDE} install ${TOOLS} -y

### Back the DEBCONF to default
unset DEBIAN_PRIORITY
unset DEBIAN_FRONTEND

# Updating the system
${APTITUDE} -y dist-upgrade

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

#Set up the backlist modules
echo "blacklist pcspkr" >> /etc/modprobe.d/blacklist.conf

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
0 */8      *       *       *       /usr/bin/aptitude update
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

# Removing the needless packets from the system
#${APTGET} remove ${REMOVABLE_PACKETS} --purge -y

#Set the default shell with fish shell
#if [ $(uname -m) == "x86_64" ]; then
#${WGET} -c http://wiki.douglasqsantos.com.br/Downloads/bacula/fish_2.1.0-1_amd64.deb -O /tmp/fish_2.1.0-1_amd64.deb
#${DPKG} -i /tmp/fish_2.1.0-1_amd64.deb
#else
#${WGET} -c http://wiki.douglasqsantos.com.br/Downloads/bacula/fish_2.1.0-1_i386.deb -O /tmp/fish_2.1.0-1_i386.deb
#${DPKG} -i /tmp/fish_2.1.0-1_i386.deb
#fi

#${CHSH} -s /usr/bin/fish
#echo "set -x EDITOR vim" >> /etc/fish/config.fish

# Rebooting the system for read all news configurations
${REBOOT}
