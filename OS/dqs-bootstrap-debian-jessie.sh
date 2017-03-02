#!/bin/bash
#-------------------------------------------------------------------------
# ConfInicialjessie
#
# Site  : http://wiki.douglasqsantos.com.br
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

### GLOBAL VARIABLES
### Defining if the script will run only the minimum configuration or the full one
# Please use upper case LETTERS
TINY="NO"
# SSH port that will be used to bind on.
SSH_PORT="22890"
# Common user that will be put on the sudo group that will be used to log in
COMMON_USER=""
# Define if the firmwares needs to be downloaded or not
# Please use upper case LETTERS
GET_FIRMWARE="NO"
# Company name in the banners
COMPANY="DQS"

### Set the colors used on the script
GREY="\033[01;30m" RED="\033[01;31m" GREEN="\033[01;32m" YELLOW="\033[01;33m"
BLUE="\033[01;34m" PURPLE="\033[01;35m" CYAN="\033[01;36m" WHITE="\033[01;37m"
CLOSE="\033[m"

# Validating who is going to execute the script
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

if [ -z "${COMMON_USER}" ]; then
  echo
  echo -e "${RED}#######################################################################################"
  echo -e " THE COMMON_USER VARIABLE IS EMPTY YOU NEED TO GIVEN SOME USER TO BE IN THE SUDO GROUP"
  echo -e " Exit..."
  echo -e "########################################################################################${CLOSE}"
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
AWK="/usr/bin/awk"
CD="cd"
GIT="/usr/bin/git"
CHSH="/usr/bin/chsh"
DOS2UNIX="/usr/bin/dos2unix"
APT="/etc/apt"
DPKG="/usr/bin/dpkg"
LOCALE_GEN="/usr/sbin/locale-gen"
GPASSWD="/usr/bin/gpasswd"
GREP="/bin/grep"
CUT="/usr/bin/cut"
CHOWN="/bin/chown"
DATE="/bin/date"
BKP=$(${DATE} +%d-%m-%Y-%H-%M-%S)
COMMON_USER_HOME=$(${CAT} /etc/passwd | ${GREP} ${COMMON_USER} | ${CUT} -d ':' -f 6)

# The Follow packets going to be removed from the system
#REMOVABLE_PACKETS="dhcp3-client dhcp3-common nfs-common"
if [ ${TINY} == "YES" ]; then
  INSTALL_PACKETS="vim vim-scripts vim-doc less locate ntpdate sudo git rsync aptitude"
  TOOLS="xz-utils unrar zip unzip rar p7zip bzip2"
else
  INSTALL_PACKETS="vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf rsync build-essential linux-headers-$(uname -r) libncurses5-dev ntpdate postfix cmake sudo git makepasswd"
  TOOLS="atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm sdparm iotop atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan"
fi

#PLUS_TOOLS="mytop ptop dnstop vnstat"

# Performing the sources.list backup
${CP} -Rf ${APT}/sources.list ${APT}/sources.list.${BKP} 2> /dev/null

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
# ${GPG} --keyserver pgpkeys.mit.edu --recv-keys 65558117
# ${APT_KEY} add ~root/.gnupg/pubring.gpg

#Updating debian priority and frontend
export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive

### updating the system locales
${SED} -i 's/# pt_BR ISO-8859-1/pt_BR ISO-8859-1/g' /etc/locale.gen
${SED} -i 's/# pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/g' /etc/locale.gen
${SED} -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
${LOCALE_GEN}

# Updating the repositories
${APTGET} -y update

### Changing the DEBCONF to CRITICAL, to install the packets without prompts questions ###
export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive

# Updating the distro
${APTGET} upgrade -y

# Updating the keys repositories (KEYRINGS)
${APTGET} -y install debian-archive-keyring debian-edu-archive-keyring debian-keyring debian-ports-archive-keyring emdebian-archive-keyring

# Installing the packets
${APTITUDE} install ${INSTALL_PACKETS} -y
${APTITUDE} install ${TOOLS} -y

### Back the DEBCONF to default
unset DEBIAN_PRIORITY
unset DEBIAN_FRONTEND

# Updating the system
${APTITUDE} -y dist-upgrade

### Defining the vim configuration
echo '" .vimrc - Defaults configurations
" Maintainer:   Douglas Quintiliano dos Santos <https://github.com/douglasqsantos/>
" Version:      1.0
syntax enable
"set tabstop=2
"set shiftwidth=2
"set softtabstop=2
"set expandtab
set laststatus=2
set ruler
set wildmenu
set lazyredraw
set backspace=indent,eol,start
set complete-=i
"set smarttab
set nrformats-=octal
set ttimeout
set ttimeoutlen=100
set incsearch
set autoread
map <F7> <esc>mz:%s/\s\+$//g<cr>`z
highlight RedundantWhitespace ctermbg=red guibg=red
match RedundantWhitespace /\s\+$\| \+\ze\t/
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [line,column=%04l,%04v][%p%%]\ [LINES=%L]
set laststatus=2' >>  /etc/skel/.vimrc

# Copying the file to the root home dir
${CP} -Rfa /etc/skel/.vimrc /root/.vimrc

### Clear the terminal on the logout
echo "clear" > .bash_logout

### Making the backup to bashrc
${CP} /root/.bashrc /root/.bashrc.${BKP}

# Will be set up the bashrc with a new configuration
${CAT} << EOF > /root/.bashrc
# ~/.bashrc
### Setting up the PS1 equal: root@hostname:~#
PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '

### Defining the alias used by the root user
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

### Defining the default editor used by the root user
export EDITOR=vim

### Defining the history format used by the history command
export HISTTIMEFORMAT="%h/%d - %H:%M:%S "

### Defining the language used by the root user
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

### Exporting the timezone change to your needs
TZ='America/Sao_Paulo'; export TZ

# The system will kick you out after 120 seconds if you be idle
# TMOUT=120


### Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

### Defining that the root user can receive messages from another users
### into the system
mesg y
EOF

# Backup the .bashrc original file inside /etc/skel
${CP} -Rfa /etc/skel/.bashrc /etc/skel/.bashrc.${BKP}

# Will be set up the bashrc with a new configuration to new users
${CAT} << EOF > /etc/skel/.bashrc
# ~/.bashrc
### Setting up the PS1 equal: user@hostname:~#
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '

### Defining the alias used by the root user
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

### Defining the default editor used by the root user
export EDITOR=vim

### Defining the history format used by the history command
export HISTTIMEFORMAT="%h/%d - %H:%M:%S "

### Defining the language used by the root user
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

### Exporting the timezone change to your needs
TZ='America/Sao_Paulo'; export TZ

# The system will kick you out after 120 seconds if you be idle
# TMOUT=120

### Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

### Defining that the root user can receive messages from another users
### into the system
mesg y
EOF

# Configuring the shell of the common user
${CP}  -Rfa ${COMMON_USER_HOME}/.bashrc ${COMMON_USER_HOME}/.bashrc.${BKP}
${CP} /etc/skel/.bashrc ${COMMON_USER_HOME}/.bashrc

# Configuring the vimrc of the common user
${CP} -Rfa ${COMMON_USER_HOME}/.vimrc ${COMMON_USER_HOME}/.vimrc.${BKP} 2> /dev/null

# Copying the file to the common user home dir
${CP} -Rfa /etc/skel/.vimrc ${COMMON_USER_HOME}/.vimrc

# Amending the file permissions
${CHOWN} ${COMMON_USER}:${COMMON_USER} ${COMMON_USER_HOME}/.vimrc ${COMMON_USER_HOME}/.bashrc

${CP} -Rfa /etc/motd /etc/motd.${BKP}
${CAT} << EOF > /etc/motd
############################################################################################################
# ALERT! You are entering into a secured area!                                                             #
# Your IP, Login Time, Username has been noted and has been sent to the server administrator!              #
# This service is restricted to authorized users only. All activities on this system are logged.           #
# Unauthorized access will be fully investigated and reported to the appropriate law enforcement agencies. #
############################################################################################################
EOF

${CP} -Rfa /etc/issue /etc/issue.${BKP}
${CAT} << EOF > /etc/issue
###############################################################
#  Welcome to ${COMPANY}                                      #
#  All connections are monitored and recorded                 #
#  Disconnect IMMEDIATELY if you are not an authorized user!  #
###############################################################
EOF

${CP} -Rfa /etc/issue.net /etc/issue.net.${BKP}
${CAT} << EOF > /etc/issue.net
###############################################################
#  Welcome to ${COMPANY}                                      #
#  All connections are monitored and recorded                 #
#  Disconnect IMMEDIATELY if you are not an authorized user!  #
###############################################################
EOF

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
if [ ${GET_FIRMWARE} == "YES" ]; then
  ${CD} /usr/src
  ${GIT} clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git firmware
  ${CP} -Rfa firmware /lib/firmware/
  ${RM} -rf /usr/src/firmware
fi

# Removing the needless packets from the system
#${APTGET} remove ${REMOVABLE_PACKETS} --purge -y

## Enabling the root sshd
# ${SED} -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
${CP} -Rfa /etc/ssh/sshd_config /etc/ssh/sshd_config.${BKP}
${CAT} << EOF > /etc/ssh/sshd_config
# /etc/ssh/sshd_config
# See the sshd_config(5) manpage for details
# Specifies the port number that sshd(8) listens on.
Port ${SSH_PORT}
# Specifies the local addresses sshd(8) should listen on.
#ListenAddress ::
#ListenAddress 0.0.0.0
# Specifies the protocol versions sshd(8) supports.
Protocol 2
# HostKeys for protocol version 2
# Specifies a file containing a private host key used by SSH.
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
# Specifies whether sshd(8) separates privileges by creating an unprivileged child process to deal with incoming network traffic.
UsePrivilegeSeparation yes
# In protocol version 1, the ephemeral server key is automatically regenerated after this many seconds (if it has been used).
KeyRegenerationInterval 3600
#  Defines the number of bits in the ephemeral protocol version 1 server key.
ServerKeyBits 1024
# Gives the facility code that is used when logging messages from sshd(8).
SyslogFacility AUTH
# Gives the verbosity level that is used when logging messages from sshd(8).
LogLevel INFO
# The server disconnects after this time if the user has not successfully logged in.
LoginGraceTime 120
# Specifies whether root can log in using ssh(1).
PermitRootLogin no
# Specifies whether sshd(8) should check file modes and ownership of the user's files and home directory before accepting login.
StrictModes yes
# Specifies whether pure RSA authentication is allowed.
RSAAuthentication yes
# Specifies whether public key authentication is allowed.
PubkeyAuthentication yes
#AuthorizedKeysFile	%h/.ssh/authorized_keys
# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes
# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no
# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no
# Change to no to disable tunnelled clear text passwords
#PasswordAuthentication yes
# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
# Specifies whether X11 forwarding is permitted.
X11Forwarding yes
# Specifies the first display number available for sshd(8)'s X11 forwarding.
X11DisplayOffset 10
# Specifies whether sshd(8) should print /etc/motd when a user logs in interactively.
PrintMotd no
# Specifies whether sshd(8) should print the date and time of the last user login when a user logs in interactively.
PrintLastLog yes
# Specifies whether the system should send TCP keepalive messages to the other side.
TCPKeepAlive yes
# Specifies whether login(1) is used for interactive login sessions.
#UseLogin no
# The contents of the specified file are sent to the remote user before authentication is allowed.
Banner /etc/issue.net
# Allow client to pass locale environment variables
AcceptEnv LANG LC_*
# Configures an external subsystem (e.g. file transfer daemon).
# Alternately the name “internal-sftp” implements an in-process “sftp” server.
# This may simplify configurations using ChrootDirectory to force a different filesystem root on clients.
Subsystem sftp /usr/lib/openssh/sftp-server
# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing.
UsePAM yes
# Specifies the maximum number of concurrent unauthenticated connections to the SSH daemon.
# Additional connections will be dropped until authentication succeeds or the LoginGraceTime expires for
# a connection.  The default is 10:30:100.
MaxStartups 3:50:6
# This keyword can be followed by a list of group name patterns, separated by spaces.
AllowGroups sudo
# Specifies whether the distribution-specified extra version suffix is included during initial protocol handshake.
# The default is “yes”.
DebianBanner no
# Specifies the maximum number of open sessions permitted per network connection.  The default is 10.
MaxSessions 3
# Specifies whether sshd(8) should look up the remote host name and check that the resolved host name
# for the remote IP address maps back to the very same IP address.  The default is “yes”.
UseDNS no
EOF

### Defining the user that will be put in the sudo group
${GPASSWD} -a ${COMMON_USER} sudo

### Creating the list of installed packages
${DPKG} -l | ${AWK} '{print $2,$3}' | ${SED} '1,5d' > /root/packages-${BKP}.txt

# Rebooting the system for read all news configurations
${REBOOT}
