#!/bin/sh
#-------------------------------------------------------------------------
# ConfInicialOpenBSD56
#
# Site  : http://www.douglas.wiki.br
# Author : Douglas Q. dos Santos <douglas.q.santos@gmail.com>
# Management: Douglas Q. dos Santos <douglas.q.santos@gmail.com>
#
#-------------------------------------------------------------------------
# Note: This Shell Script set up the initial configuration to OpenBSD56
# where install the needed packets and configure some packets
#-------------------------------------------------------------------------
# History:
#
# Version 1:
# Data: 08/07/2014
# Description: Set up the initial configuration of OpenBSD 5.6
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
PKG_ADD="/usr/sbin/pkg_add"
CAT="/bin/cat"
CRONTAB="/usr/bin/crontab"
CP="/bin/cp"
TAR="/bin/tar"
RM="/bin/rm"
NTPDATE="/usr/sbin/ntpdate"
REBOOT="/sbin/reboot"
WGET="/usr/local/bin/wget"
MKDIR="/bin/mkdir"
CD="cd"
FIRST_PKG="http://mirror.internode.on.net/pub/OpenBSD/5.6/packages/`machine -a`/"
SECOND_PKG="http://mirror.aarnet.edu.au/pub/OpenBSD/5.6/packages/`machine -a`/"
FIRST_CVS="anoncvs@ftp5.eu.openbsd.org:/cvs"
CHSH="/usr/bin/chsh"
FTP="/usr/bin/ftp"
DOS2UNIX="/usr/local/bin/dos2unix"
PORTS="http://mirror.aarnet.edu.au/pub/OpenBSD/5.6/ports.tar.gz"

INSTALL_PACKETS="vim-7.4.135p2-no_x11 wget ntp dos2unix colorls nmap iftop python-2.7.8 metaauto autoconf-2.69p1 help2man gmake rsync-3.1.1 git gnugetopt bash"

#Set up the repository
export PKG_PATH=${FIRST_PKG}

# Installing the packets
echo -e  "${RED}INSTALLING SOME PACKAGETS WAIT FOR A FEW MINUTES${CLOSE}"
${PKG_ADD} -v ${INSTALL_PACKETS}

# Download the configuration file to VIM
echo -e  "${RED}GETTING THE VIM CONFIGURATION ${CLOSE}"
${WGET} -c http://www.douglas.wiki.br/Downloads/scripts/.vimrc -O /root/.vimrc

#Convert the file to Unix format
echo -e  "${RED}CONVERTING THE VIMRC TO UNIX FORMAT${CLOSE}"
${DOS2UNIX} /root/.vimrc

echo -e  "${RED}CONFIGURING THE .BASHRC TO ROOT USER${CLOSE}"
echo ". .bashrc" >> /root/.profile

# Will be set up the bashrc with a new configuration
${CAT} << EOF > /root/.bashrc
#.bashrc
    PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '

    alias ls='/usr/local/bin/colorls -G'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'


# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

export EDITOR=vim
export PAGER=less
export HISTTIMEFORMAT="%h/%d - %H:%M:%S "

export PKG_PATH=${FIRST_PKG}
export ALT_PKG_PATH=${SECOND_PKG}
export CVSROOT=${FIRST_CVS}

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

ulimit -n 65536
mesg y
EOF

# Will be set up the bashrc with a new configuration to new users
${CAT} << EOF > /etc/skel/.bashrc
#.bashrc
    PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '

    alias ls='/usr/local/bin/colorls -G'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'


# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

export EDITOR=vim
export PAGER=less
export HISTTIMEFORMAT="%h/%d - %H:%M:%S "

export PKG_PATH=${FIRST_PKG}
export ALT_PKG_PATH=${SECOND_PKG}
export CVSROOT=${FIRST_CVS}

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

ulimit -n 65536
mesg y
EOF

#Fetch the ports and extracting
echo -e  "${RED}FETCHING PORTS IT MIGHT DELAY A LITTLE BIT${CLOSE}"
${CD} /usr
${FTP} ${PORTS}
${TAR} xzvf ports.tar.gz
${RM} -rf ports.tar.gz

# Set up the Crontab
CRON=/tmp/cron

# Tasks scheduled on the Cron
echo -e  "${RED}CONFIGURING CRONTAB TO ROOT USER${CLOSE}"
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
0 */6      *       *       *       /usr/sbin/ntpdate -u a.ntp.br
EOF

# Remove the current crontab
${CRONTAB} -r

# For to Schedule the new crontab
${CRONTAB} ${CRON}

# Removing the temp crontab
${RM} -rf ${CRON}

#CHANGING DEFAULT SHELL FOR ROOT
echo -e  "${RED}SET UP SHELL BASH TO ROOT USER${CLOSE}"
${CHSH} -s /usr/local/bin/bash

#Configuring options for make
echo -e  "${RED}CREATING SOME PARAMETERS TO MK.CONF${CLOSE}"
${CAT} << EOF > /etc/mk.conf
WRKOBJDIR=/usr/obj/ports
DISTDIR=/usr/distfiles
PACKAGE_REPOSITORY=/usr/packages
PORTSDIR=/usr/ports
PORTSDIR_PATH=\${PORTSDIR}:\$(PORTSDIR)/openbsd-wip
EOF

# Rebooting the system for read all news configurations
echo -e  "${RED}REBOOTING${CLOSE}"
${REBOOT}
