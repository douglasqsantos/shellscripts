#!/bin/bash
#-------------------------------------------------------------------------
# ConfInicialjessie
#
# Site  : http://www.douglas.wiki.br
# Author : Douglas Q. dos Santos <douglas.q.santos@gmail.com>
# Management: Douglas Q. dos Santos <douglas.q.santos@gmail.com>
#
#-------------------------------------------------------------------------
# Note: This Shell Script set up the initial configuration to Debian jessie
# where install the needed packets and configure some packets
#-------------------------------------------------------------------------
# History:
#
# Version 1:
# Data: 26/04/2015
# Description: Set up the initial configuration of Debian GNU/Linux jessie
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
LOCALE_GEN="/usr/sbin/locale-gen"

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
deb http://ftp.br.debian.org/debian jessie main contrib non-free
deb-src http://ftp.br.debian.org/debian jessie main contrib non-free


# Security update repository
deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free

# Propose update repository
deb http://ftp.br.debian.org/debian jessie-proposed-updates main contrib non-free
deb-src http://ftp.br.debian.org/debian jessie-proposed-updates main contrib non-free


# Backport repository
#deb http://ftp.br.debian.org/debian jessie-backports main contrib non-free
#deb-src http://ftp.br.debian.org/debian jessie-backports main contrib non-free

# Multimedia repository
#deb http://ftp.br.debian.org/debian-multimedia/ jessie main non-free
#deb-src http://ftp.br.debian.org/debian-multimedia/ jessie main non-free

# PHP5 BACKPORT
#deb http://packages.dotdeb.org jessie all
#deb-src http://packages.dotdeb.org jessie all

EOF

## Updating the keys repositories
${GPG} --keyserver pgpkeys.mit.edu --recv-keys 65558117
${APT_KEY} add ~root/.gnupg/pubring.gpg

#Updating debian priority and frontend
export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive

### updating the system locales
${SED} -i 's/# pt_BR ISO-8859-1/pt_BR ISO-8859-1/g' /etc/locale.gen
${SED} -i 's/# pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/g' /etc/locale.gen
${SED} -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
${LOCALE_GEN}

# Updating the repositories
${APTITUDE} -y update

# Updating the keys repositories (KEYRINGS)
${APTITUDE} -y install debian-archive-keyring debian-edu-archive-keyring debian-keyring debian-ports-archive-keyring emdebian-archive-keyring

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
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
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
${RM} -rf /usr/src/firmware

# Removing the needless packets from the system
#${APTGET} remove ${REMOVABLE_PACKETS} --purge -y

#Set the default shell with fish shell
${WGET} -c http://www.douglas.wiki.br/Downloads/misc/fish_2.1.1-1_amd64.deb -O /tmp/fish_2.1.1-1_amd64.deb
${DPKG} -i /tmp/fish_2.1.1-1_amd64.deb

### Set some global variables
echo "set -x -U EDITOR 'vim'" >> /etc/fish/config.fish
echo "set -x -U TZ 'America/Sao_Paulo'" >> /etc/fish/config.fish

## Enabling the root sshe
${SED} -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Rebooting the system for read all news configurations
${REBOOT}
