#!/bin/bash
#-------------------------------------------------------------------------
# documentacao-0.4.sh
#
# Site  : http://www.douglas.wiki.br
# Author : Douglas Q. dos Santos <douglas.q.santos@gmail.com>
# Management: Douglas Q. dos Santos <douglas.q.santos@gmail.com>
#
#-------------------------------------------------------------------------
# Note: This Shell Script make the documentation about your server
# with some informations that you need to know about your server
#-------------------------------------------------------------------------
# History:
#
# Version 1:
# Data: 06/12/2014
# Description:  Documentation about your server
# ### documentacao-0.4.sh Working with functions to cheking
#
#--------------------------------------------------------------------------
#License: http://creativecommons.org/licenses/by-sa/3.0/legalcode
#
#--------------------------------------------------------------------------
clear

_SET_VAR(){
#Set the colors used on the script
GREY="\033[01;30m" RED="\033[01;31m" GREEN="\033[01;32m" YELLOW="\033[01;33m"
BLUE="\033[01;34m" PURPLE="\033[01;35m" CYAN="\033[01;36m" WHITE="\033[01;37m"
CLOSE="\033[m"
 
#Validating who is going to execute the script
USU=$(whoami)

### Commands used on the script
CAT=$(which cat)
DPKG=$(which dpkg)
RPM=$(which rpm)
GREP=$(which grep)
EGREP=$(which egrep)
LS=$(which ls)
NMAP=$(which nmap)
TREE=$(which tree)
UNAME=$(which uname)
UNIQ=$(which uniq)
SED=$(which sed)
INSTALLER=$(which aptitude)
APTITUDE=$(which aptitude)
YUM=$(which yum)
LOCALE=$(which locale)
RUNLEVEL=$(which runlevel)
UPTIME=$(which uptime)
TYPE="type"
LAST=$(which last)
FREE=$(which free)
FDISK=$(which fdisk)
DF=$(which df)
LSPCI=$(which lspci)
LSUSB=$(which lsusb)
LSMOD=$(which lsmod)
IFCONFIG=$(which ifconfig)
ROUTE=$(which route)
SHOWMOUNT=$(which showmount)
APACHECTL=$(which apachectl)
CLEAR=$(which clear)
SORT=$(which sort)
SLAPCAT=$(which slapcat)
PVDISPLAY=$(which pvdisplay)
VGDISPLAY=$(which vgdisplay)
LVDISPLAY=$(which lvdisplay)
ISCSIADM=$(which iscsiadm)
RUNL=$(runlevel | awk '{ print $2 }')
DOC="$(uname -n)".html
AUTHOR="Douglas Quintiliano dos Santos"
TITLE="Documentação do Servidor: $(hostname)"
DESCRIPTION="Documentação do Servidor: $(hostname)"
#http://www.w3schools.com/tags/ref_language_codes.asp
LANGUAGE="pt"

### DIRECTORIES
BIND_BASE="/var/lib/named"
BIND_BASE2="/var/named/chroot"

### Packets that we need to install
PKGS_CENTOS="nmap pciutils tree usbutils"
PKGS_DEBIAN="nmap pciutils tree usbutils"
}


### Function to warning the user about what we'll do.
_INIT(){
if [ "${USU}" != "root" ]; then
  echo -e "${RED}========================================================================"
  echo -e " THIS SCRIPT NEED TO BE EXECUTED AS ROOT! "
  echo -e " ABORTING..."
  echo -e "========================================================================${CLOSE}"
  exit 1
fi

### Show to user that we'll do now
echo -e "${RED} INSTALLING SOME PACKETS ${CLOSE} "

### Check if dpkg exists or not
if [ ! -z "${DPKG}" ]; then
    ### Install the packets with aptitude
	${APTITUDE} install ${PKGS_DEBIAN} -y
else
    ### Install the packets with yum
	${YUM} install ${PKGS_CENTOS} -y
fi

### Show to user that we'll do the documentation now
echo -e "${GREEN} THE DOCUMENTATION IS ONGOING... ${CLOSE}"
}

### Header to your script
_WARNING() {
#${CLEAR}
  echo -e "${GREEN}========================================================================"
  echo -e "                           DOCUMENTATION SYSTEM"
  echo -e "========================================================================${CLOSE}"
  echo -e "${GREEN} USING THE FOLLOW NAME FOR YOUR DOCUMENTATION: ${CLOSE} ${RED} ${DOC} ${CLOSE}"
}

_HWARNING(){
### Function to set up the header for each function

### Variable to set up the name for our message
MSG="$1"

  echo -e "${GREEN} RUNNING THE FOLLOW CHECKING: ${CLOSE} ${RED} ${MSG} ${CLOSE}"
}

_FWARNING(){
### Function to set up the header for each function

### Variable to set up the name for our message
MSG="$1"

  echo -e "${GREEN} FINISHED TO RUNNING THE FOLLOW CHECKING: ${CLOSE} ${RED} ${MSG} ${CLOSE}"
}

### Header to your html file
_FILE_HEADER () {

### HEADER
_HWARNING "GENERATING THE HEADER"

### Function to set up the header to the html
${CAT} << EOF >> ${DOC}
<!DOCTYPE html>
<html lang="${LANGUAGE}">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="${DESCRIPTION} ">
    <meta name="author" content="${AUTHOR}">
    <title> ${TITLE} </title>
    
<!-- BootStrap Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">

<!-- BootStrap Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap-theme.min.css">

<!-- BootStrap Latest compiled and minified JavaScript -->
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/js/bootstrap.min.js"></script>

</head>
<body id="page-top" class="index">

    <!-- MAIN -->
        <div class="container">
EOF

echo "<h1>Documentação do Servidor: $(uname -n)</h1>" >> ${DOC}
echo "<p><b><i>Ultima atualização em:</i></b> $(date "+%d/%m/%Y %H:%M")</p>" >> ${DOC}

### FOOTER
_FWARNING "GENERATING THE HEADER"

}

### Footer to our html file
_FOOTER(){
### HEADER
_HWARNING "GENERATING THE FOOTER"

### Function used to set up the footer to the html.
${CAT} << EOF >> ${DOC}
</div>
<div id="footer">
  <div class="container">
</address>
    <p class="text-muted">Contato: <a href="http://www.confiservsolucoes.com.br">www.confiservsolucoes.com.br</a> Email:<a href="mailto:douglas@confiservsolucoes.com.br">douglas@confiservsolucoes.com.br</a></p>
  </div>
</div>
</body>
</html>
EOF

### FOOTER
_FWARNING "GENERATING THE FOOTER"

}

### Function to validate the parameters and create the html
_EMPTY(){
### Function to check it the directory is empty or not

### The directory that we'll check.
DIR="$1"

## Check if the directory is empty or not and return a value.
if [ "$(${LS} -A ${DIR})" ]; then
    ### Return it if the directory is not empty
    echo "NOT EMPTY"
 else
    ### Return it if the directory is empty
    echo "EMPTY"
fi
}

### Function to check files into a directory
_CHECK_DIR(){
### Function to check files into a directory, if it exists or not and if the result is not empty

### Variables
## Directory that we'll check if is empty or not and we'll read all files there
DIR="$1"

### The header to the section
HEADER="$2"

### The pattern that we'll check onto the directory, if it is null we'll use the "*" as default.
PATTERN="$3"

### Check if the pattern is empty or not, if it is empty we'll use the "*" as default.
if [ -z "${PATTERN}" ]; then
    ### Set up the pattern as "*" if it is empty
	PATTERN="*"
fi

### Check if the variable is empty
if [ ! -z "${DIR}" ]; then
  ### Check if the directory exists or not
  if [ -d ${DIR} ]; then
  ### Check the result about if the Directory is empty or not
  RESULT=$(_EMPTY "${DIR}")
     ### If the directory is not empty we'll check the files
     if [ "${RESULT}" != "EMPTY" ]; then 
      ### Variable used to check if the header already was set up 
      NN=""  
      ### Check all files from the directory
      for FILE in $(${LS} ${DIR}/${PATTERN} 2> /dev/null | ${EGREP} -v "(*.bkp$|*.old$|*.original$|*-dist$)")
      do
          ### Check if is file
      	  if [ -f ${FILE} ]; then
	   	  ### Check if the result of the file is empty or not
		  CHECK=$(${CAT} ${FILE} | ${EGREP} -v "^#" | ${EGREP} -v "^$" | ${EGREP} -v "^(/){2}")
			  ### If the check is not empty we'll set up the header and the value of the command.
			  if [ ! -z "${CHECK}" ]; then
					  ### We'll set up the header if the header doesn't exists yet.
					  if [ -z ${NN} ]; then
					  ### Set up the header to a group of files
					  echo "<h2> ${HEADER} </h2>" >> ${DOC}  
					  ### Change the value to HEADER because we've just set up it.
					  NN="HEADER"      
					  fi
				  ### Set up the header for each file that we read
				  echo "<h3> ${FILE} </h3>" >> ${DOC}
				  ### Here we'll put the tag pre that is used to put some value that is pre-formated
				  echo "<pre>" >> ${DOC}
				  ### Execute all command that was passed are parameters
				  ${CAT} ${FILE} | ${EGREP} -v "^(/){2}" | ${EGREP} -v "^#" | ${EGREP} -v "^$" | ${EGREP} -v "^;" | ${UNIQ} -u | ${SED} -s 's/</\&lt;/g' | ${SED} -s 's/>/\&gt;/g' >> ${DOC}
				  ### Here we'll put the close of tag pre that is used to put some value that is pre-formated
				  echo "</pre>" >> ${DOC}
			  ### Close if ! -z ${CHECK}
			  fi
		  ### Close if if file.
		  fi
      done
    ### Close if ${RESULT} != EMPTY  
    fi
  ### Close if -d ${DIR} 
  fi
### Close if ! -z ${DIR}  
fi

}

### Function to check files.
_CHECK_FILE(){
### Function to check files, if it exists or not and if the result is not empty

### Variables
### Files or Files.* that will checked
FTMP="$1"
### The header to the section
HEADER="$2"
### The first command passed to the function
CMD="$3"
### The second command passed to the function
CMD2="$4"
### The Third command passed to the function
CMD3="$5"
### The fourth command passed to the function
CMD4="$6"

### Check if file is not null
if [ ! -z "${FTMP}" ]; then

### List the file or files 
FILES=$(${LS} ${FTMP} 2> /dev/null)

## Read all files that is passed from the ${FILES}
for FILE in ${FILES}
do
    ### Check if the file exists
	if [ -f ${FILE} ]; then
	   ### Check if the header is empty if is true we'll use the ${FILE} as name
	   if [ -z "${HEADER}" ]; then
	        ### Set up the ${HEADER} as ${FILE}
	  		HEADER=${FILE}
	   fi
	   
	  ### Check if the result about the file is empty
	  CHECK=$(${CAT} ${FILE} | ${EGREP} -v "^#" | ${EGREP} -v "^$")
	  
	  ### Check if the result is not empty, after that we'll ahead
	  if [ ! -z "${CHECK}" ]; then
	  ### Define the header to the section
	  echo "<h2> ${HEADER} </h2>" >> ${DOC}
	  ### Here we'll put the tag pre that is used to put some value that is pre-formated
	  echo "<pre>" >> ${DOC}
	  ### Check if we've all command as not empty
	   if [ ! -z "${CMD}" ] && [ ! -z "${CMD2}" ] && [ ! -z "${CMD3}" ] && [ ! -z "${CMD4}" ]; then
	     ### Execute all command that was passed are parameters
	     ${CMD} | ${CMD2} | ${CMD3} | ${CMD4} >> ${DOC}
	   ### Check if the third ones parameters passed are not empty  
	   elif [ ! -z "${CMD}" ] && [ ! -z "${CMD2}" ] && [ ! -z "${CMD3}" ]; then
	     ### Execute all command that was passed as parameters
	     ${CMD} | ${CMD2} | ${CMD3} >> ${DOC}
	   ### Check if the two firt ones parameters passed are not empty
	   elif [ ! -z "${CMD}" ] && [ ! -z "${CMD2}" ]; then
	     ### Execute all command that was passed as parameters
	     ${CMD} | ${CMD2} >> ${DOC}
	   ### Check if the command is not empty
	   elif [ ! -z "${CMD}" ]; then
	     ### Execute the command that was passed as parameter
	     ${CMD} >> ${DOC}
	   ### If we don't have any command to execute, we'll only read the file and filter that we need from it
	   else
	     ### Execute all command that was passed are parameters
	     ${CAT} ${FILE} | ${EGREP} -v "^(/){2}" | ${EGREP} -v "^#" | ${EGREP} -v "^$" | ${EGREP} -v "^;" | ${UNIQ} -u | ${SED} -s 's/</\&lt;/g' | ${SED} -s 's/>/\&gt;/g' >> ${DOC} 
	   fi
	  ### Here we'll put the close of tag pre that is used to put some value that is pre-formated
	  echo "</pre>" >> ${DOC}
	 ### Close the if of ${CHECK }
	 fi
	### Close the if of (if -f ${FILE})
	fi
done
### Close the if of (! -z "${FTMP}" )
fi

}

### Function to check commands.
_CHECK_CMD(){
### Function to execute some command that was passed as argument
### and put into html

### Variables
### Command that will be executed
CMD="$1"
### The header to the section
HEADER="$2"
### The directory that will checked if exists or not.
DIR="$3"
### The command that will checked if is valid or not.
CCMD="$4"

### Check if the command is valid
if [ ! -z ${CCMD} ]; then

### Check if the dir is null or not
if [ ! -z ${DIR} ]; then
    ### Check if the dir exists or not
	if [ -d ${DIR} ]; then
		### Check if the command and the header is not null
		if [ ! -z "${CMD}" ] && [ ! -z "${HEADER}" ]; then
   	      ### Check if the result about the file is empty
	      CHECK=$(${CMD} | ${EGREP} -v "^#" | ${EGREP} -v "^$")
  	      ### Check if the result is not empty, after that we'll ahead
	      if [ ! -z "${CHECK}" ]; then
		    ### Define the header to the section
			echo "<h2> ${HEADER} </h2>" >> ${DOC}
	  		### Here we'll put the tag pre that is used to put some value that is pre-formated
			echo "<pre>" >> ${DOC}
	  		### Here we'll put the result of our command into the html
			${CMD} >> ${DOC}
	  	  	### Here we'll put the close of tag pre that is used to put some value that is pre-formated
			echo "</pre>" >> ${DOC}
		  fi
		fi
	fi
else
		### Check if the command and the header is not null
		if [ ! -z "${CMD}" ] && [ ! -z "${HEADER}" ]; then
		  ### Check if the result about the file is empty
	      CHECK=$(${CMD} | ${EGREP} -v "^#" | ${EGREP} -v "^$")
  	      ### Check if the result is not empty, after that we'll ahead
	      if [ ! -z "${CHECK}" ]; then
   		    ### Define the header to the section
			echo "<h2> ${HEADER} </h2>" >> ${DOC}
			### Here we'll put the tag pre that is used to put some value that is pre-formated
			echo "<pre>" >> ${DOC}
			### Here we'll put the result of our command into the html
			${CMD} >> ${DOC}
			### Here we'll put the close of tag pre that is used to put some value that is pre-formated
			echo "</pre>" >> ${DOC}
		  fi
		fi
fi

### Close if the command is valid
fi

}

### Function to check packets.
_CHECK_PKG(){
### Function to check if a packet is installed or not
### and put the result into html

### Variables used here
### The packet that we'll do the search
PKG="$1"
### The header for the section
HEADER="$2"

### Check all packets
if [ -z ${PKG} ]; then
	### We need to check if dpkg or rpm are installed
	if [ ! -z ${DPKG} ]; then
        ### Here we'll define the header to the section
  		echo "<h1> ${HEADER} </h1>" >> ${DOC}
  		### Here we'll put the tag pre that is used to put some value that is pre-formated
  		echo "<pre>" >> ${DOC}
  		### Here we'll put the result about our consult into the html
  	  	${DPKG} -l >> ${DOC}
  	  	### Here we'll put the close of tag pre that is used to put some value that is pre-formated
 	    echo "</pre>" >> ${DOC}
	else 
        ### Here we'll define the header to the section
		echo "<h1> ${HEADER} </h1>" >> ${DOC}
		### Here we'll put the tag pre that is used to put some value that is pre-formated
  		echo "<pre>" >> ${DOC}
  		### Here we'll put the result about our consult into the html
	    ${RPM} -qav | ${SORT} >> ${DOC}
   	  	### Here we'll put the close of tag pre that is used to put some value that is pre-formated
	    echo "</pre>" >> ${DOC}
	 fi
else
### We need to check if dpkg or rpm are installed
if [ ! -z ${DPKG} ]; then

   ### Here we'll check if the packet is intalled or not with dpkg
   CHECK=$(${DPKG} -l | ${EGREP} ${PKG})
   
     ### If we've some result about the packet we'll put it into html
     if [ ! -z "${CHECK}" ]; then
        ### Here we'll define the header to the section
  		echo "<h1> ${HEADER} </h1>" >> ${DOC}
  		### Here we'll put the tag pre that is used to put some value that is pre-formated
  		echo "<pre>" >> ${DOC}
  		### Here we'll put the result about our consult into the html
  	  	${DPKG} -l | ${EGREP} "${PKG}" >> ${DOC}
  	  	### Here we'll put the close of tag pre that is used to put some value that is pre-formated
 	    echo "</pre>" >> ${DOC}
     fi
else
   ### Here we'll check if the packet is intalled or not with rpm
   CHECK=$(${RPM} -qav | ${EGREP} ${PKG})
   
     ### If we've some result about the packet we'll put it into html
     if [ ! -z "${CHECK}" ]; then
        ### Here we'll define the header to the section
		echo "<h1> ${HEADER} </h1>" >> ${DOC}
		### Here we'll put the tag pre that is used to put some value that is pre-formated
  		echo "<pre>" >> ${DOC}
  		### Here we'll put the result about our consult into the html
	    ${RPM} -qav | ${EGREP} "${PKG}" | ${SORT} >> ${DOC}
   	  	### Here we'll put the close of tag pre that is used to put some value that is pre-formated
	    echo "</pre>" >> ${DOC}
	 fi

### Close the check about dpkg or rpm are installed	 
fi

### Close check all packets
fi
}


### Below we've the function that will generate the documentation ###
_SYSTEM_INFO () {

### HEADER
_HWARNING "GENERATING SYSTEM INFO"

echo "<hr />" >> ${DOC}
echo "<h1> Informações do Sistema </h1>" >> ${DOC}

_CHECK_CMD "${UNAME} -n" "Nome da Máquina" "" "${UNAME}"

_CHECK_CMD "${UNAME} -sr" "Versão do Kernel" "" "${UNAME}"

_CHECK_FILE "/etc/debian_version" "Versão da Distro"

_CHECK_FILE "/etc/redhat-release" "Versão da Distro"

_CHECK_FILE "/etc/lsb-release" "Informações Específicas da Distro"

_CHECK_CMD "${LOCALE}" "Locale Configurado" "" "${LOCALE}"

_CHECK_CMD "${RUNLEVEL}" "Runlevel do Sistema" "" "${RUNLEVEL}"

_CHECK_CMD "${UPTIME}" "Uptime do Sistema e Load Average" "" "${UPTIME}"

_CHECK_CMD "${LS} /etc/rc${RUNL}.d/S*" "Serviços Configurados" "" "${LS}"

_CHECK_FILE "/var/log/wtmp" "Reinicializações da Máquina" "${LAST}" "${EGREP} boot"

_CHECK_FILE "/etc/hosts" "Hosts e IPs"

_CHECK_CMD "${NMAP} -sS -n -v 127.0.0.1 -T4 " "Portas Abertas TCP" "" "${NMAP}"

_CHECK_CMD "${NMAP} -sU -n -v 127.0.0.1 -T4 " "Portas Abertas UDP" "" "${NMAP}"

_CHECK_CMD "${TREE} -d -L 1 /etc" "Estrutura do Diretório /etc" "" "${TREE}"

_CHECK_CMD "${TREE} -d -L 1 /boot" "Estrutura do Diretório /boot" "" "${TREE}"

_CHECK_CMD "${TREE} -d -L 1 /home" "Estrutura do Diretório /home" "" "${TREE}"

_CHECK_CMD "${TREE} -d -L 1 /usr" "Estrutura do Diretório /usr" "" "${TREE}"

_CHECK_CMD "${TREE} -d -L 1 /tmp" "Estrutura do Diretório /tmp" "" "${TREE}"

_CHECK_CMD "${TREE} -d -L 1 /srv" "Estrutura do Diretório /srv" "" "${TREE}"

_CHECK_FILE "/etc/passwd" "Usuários do Sistema Local"

_CHECK_FILE "/etc/group" "Grupos do Sistema Local"

_CHECK_FILE "/etc/modprobe.d/aliases" "Módulos do Sistema"

_CHECK_FILE "/etc/nsswitch.conf" "Controle de consulta de usuários e grupos no sistema"

_CHECK_FILE "/etc/sysctl.conf" "Variáveis do Kernel pré-definidas"

_CHECK_CMD "${LSMOD}" "Módulos carregados" "" "${LSMOD}"

_CHECK_FILE "/etc/sudoers" "Configurações de Sudo"

_CHECK_FILE "/etc/apt/sources.list" "Repositórios Padrões"

_CHECK_DIR "/etc/apt/sources.list.d" "Arquivos de Configuração de Repositórios Extras"

_CHECK_DIR "/etc/yum.repos.d" "Arquivos de Configuração de Repositórios"

### FOOTER
_FWARNING "GENERATING SYSTEM INFO"

}

_HARDWARE () {

### HEADER
_HWARNING "GENERATING HARDWARE INFO"

echo "<hr />" >> ${DOC}
echo "<h1> Informações de Hardware </h1>" >> ${DOC}

_CHECK_FILE "/proc/cpuinfo" "Informações do Processador"

_CHECK_FILE "/proc/meminfo" "Informações de Memória"

_CHECK_CMD "${FREE} -m" "Informações de Memória no Estado Atual" "" "${FREE}"

_CHECK_CMD "${FDISK} -l" "Particionamentos dos discos locais" "" "${FDISK}"

_CHECK_CMD "${DF} -hT" "Partições Montadas e Sistema de Arquivos" "" "${DF}"

_CHECK_FILE "/etc/fstab" "Pontos de Montagens das Partições"

_CHECK_FILE "/proc/mdstat" "Informações de RAID disponíveis"

_CHECK_CMD "${PVDISPLAY} -v" "Informações de Volumes Físicos LVM:(PVs)" "" "${PVDISPLAY}"

_CHECK_CMD "${VGDISPLAY} -v" "Informações de Grupo de Volumes LVM:(VGs)" "" "${VGDISPLAY}"

_CHECK_CMD "${LVDISPLAY} -v" "Informações de Volumes Lógicos LVM:(LVs)" "" "${LVDISPLAY}"

_CHECK_CMD "${LSPCI}" "Dispositivos PCI Instalados" "" "${LSPCI}"

_CHECK_CMD "${LSUSB}" "Dispositivos USB Instalados" "" "${LSUSB}"

### FOOTER
_FWARNING "GENERATING HARDWARE INFO"

}

_BOOT () {

### HEADER
_HWARNING "GENERATING BOOT INFO"

echo "<hr />" >> ${DOC}
echo "<h1> Informações de Boot </h1>" >> ${DOC}

_CHECK_PKG "(grub[2]?-)" "Pacotes do Serviço Grub"

_CHECK_CMD "${LS} /boot/* " "Lista de arquivos do /boot" "" "${LS}"

_CHECK_FILE "/boot/grub/menu.lst" "Arquivo de configuração do GRUB"

_CHECK_FILE "/boot/grub/grub.cfg" "Arquivo de configuração do GRUB 2"

### FOOTER
_FWARNING "GENERATING BOOT INFO"

}

_REDE () {

### HEADER
_HWARNING "GENERATING NETWORK INFO"

echo "<hr />" >> ${DOC}
echo "<h1> Informações da Rede </h1>" >> ${DOC}

_CHECK_FILE "/etc/network/interfaces" "Arquivo(s) de configuração de Rede"

_CHECK_DIR "/etc/sysconfig/network-scripts" "Arquivo de configuração de Rede" "ifcfg-eth*"

_CHECK_CMD "${IFCONFIG}" "Endereços IPS" "" "${IFCONFIG}"

_CHECK_CMD "${ROUTE} -n" "Informações de Roteamento" "" "${ROUTE}"

### FOOTER
_FWARNING "GENERATING NETWORK INFO"

}

_ISCSI() {

### HEADER
_HWARNING "GENERATING ISCSI INFO"

_CHECK_PKG "(iscsi|multipath)" "Pacotes do Serviço ISCSI"

_CHECK_DIR "/etc/iscsi" "Arquivo de configuração da ISCSI" "*.[ci]*"

_CHECK_DIR "/etc/iscsi/ifaces" "Arquivo de configuração das interfaces ISCSI"

_CHECK_CMD "${ISCSIADM} -m session -P 2" "Informações de Conexões SCSI" "" "${ISCSIADM}"

_CHECK_FILE "/etc/multipath.conf" "Arquivo de configuração de Multipath"

### FOOTER
_FWARNING "GENERATING ISCSI INFO"

}


_INSTALLED_PKG(){

### HEADER
_HWARNING "GENERATING ALL PACKETS INFO"

_CHECK_PKG "" "Relação de pacotes‌ instalados"

### FOOTER
_FWARNING "GENERATING ALL PACKETS INFO"

}

_NFS () {

### HEADER
_HWARNING "GENERATING NFS INFO"

_CHECK_PKG "(nfs-)" "Pacotes do Serviço NFS"

_CHECK_FILE "/etc/exports" "Configurações do NFS"

_CHECK_FILE "/etc/exports" "Diretorios Exportados via NFS" "${SHOWMOUNT} -e 127.0.0.1"

### FOOTER
_FWARNING "GENERATING NFS INFO"

}

_SAMBA () {

### HEADER
_HWARNING "GENERATING SAMBA INFO"

_CHECK_PKG "(samba[4]?-|smbclient|krb)" "Pacotes do Serviço Samba"

_CHECK_FILE "/etc/samba/smb.conf" " Arquivos de Configuração do Samba"

_CHECK_FILE "/etc/krb5.conf" " Arquivos de Configuração do Cliente Kerberos"

### FOOTER
_FWARNING "GENERATING SAMBA INFO"

}

_LDAP () {

### HEADER
_HWARNING "GENERATING LDAP INFO"

_CHECK_PKG "(ldap)" "Pacotes do Serviço LDAP"

_CHECK_DIR "/etc/ldap/slapd.d" "Arquivo de Controle do Servidor LDAP" "*.ldif"

_CHECK_CMD "${SLAPCAT}" "Lista da estrutura do LDAP" "" "${SLAPCAT}"

_CHECK_DIR "/etc/ldap/sasl2" "Arquivo de configuração do SASL para o LDAP"

_CHECK_DIR "/etc/ldap/schema" "Arquivo(s) de Schema do LDAP" "*.[ls]*"

_CHECK_DIR "/etc/ldap/slapd.d/cn=config" "Arquivo(s) de Configuração do Servidor LDAP" "*.ldif"

_CHECK_DIR "/etc/ldap/slapd.d/cn=config/cn=schema" "Arquivo(s) de Configuração dos Schema Servidor LDAP" "*.ldif"

_CHECK_DIR "/etc/ldap/slapd.d/cn=config/olcDatabase={1}hdb" "Arquivo de Configuração da replicação do Servidor LDAP" "*.ldif"

_CHECK_FILE "/etc/ldap/ldap.conf" "Arquivo de configuração do Cliente LDAP"

_CHECK_FILE "/etc/openldap/ldap.conf" "Arquivo de configuração do Cliente LDAP"

_CHECK_FILE "/etc/pam_ldap.conf" "Arquivo de configuração da PAM para o Cliente LDAP"

_CHECK_FILE "/etc/pam_ldap.secret" "Arquivo complementar de configuração da PAM para o Cliente LDAP"

_CHECK_FILE "/etc/nslcd.conf" "Arquivo de configuração da PAM com NSS para o Cliente LDAP"

_CHECK_FILE "/etc/libnss-ldap.conf" "Arquivo de configuração da PAM com NSS para o Cliente LDAP"

_CHECK_FILE "/etc/libnss-ldap.secret" "Arquivo complementar de configuração da PAM com NSS para o Cliente LDAP"

### FOOTER
_FWARNING "GENERATING LDAP INFO"

}




_PAM () {

### HEADER
_HWARNING "GENERATING PAM INFO"

echo "<hr />" >> ${DOC}
echo "<h1> Informações da PAM </h1>" >> ${DOC}

_CHECK_PKG "(pam)" "Pacotes do Serviço PAM"

_CHECK_DIR "/etc/pam.d" "Arquivos de Configuração da PAM"

### FOOTER
_FWARNING "GENERATING PAM INFO"

}

_BACULA () {

### HEADER
_HWARNING "GENERATING BACULA INFO"

### Here we need to check if the directory exists or not because all bacula clients was installed with source files
if [ -d /etc/bacula/ ]; then
echo "<hr />" >> ${DOC}
echo "<h1> Informações do Serviço Bacula </h1>" >> ${DOC}

_CHECK_CMD "${TREE} -d -L 3 /etc/bacula" "Estrutura de Diretórios do Bacula" "" "${TREE}"

_CHECK_DIR "/etc/bacula" "Arquivos de Configuração do Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/keys" "Certificados do Bacula" "*.[ck]*"

_CHECK_DIR "/etc/bacula/clients-jobs" "Definições de Serviços do Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/devices" "Definições de Devices do Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/filesets" "Definições do que vai ser copiado dos Clientes Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/jobsdef" "Definições padrões para Serviços do Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/pools" "Definições de Pool para Serviços do Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/schedules" "Definições de Agendamentos para Serviços do Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/storages" "Definições de Armazenamento para Serviços do Bacula" "*.conf" 

_CHECK_DIR "/etc/bacula/scripts" "Definições de Scripts do Bacula" "*.sh" 

fi

### FOOTER
_FWARNING "GENERATING BACULA INFO"

}

_ZABBIX(){

### HEADER
_HWARNING "GENERATING ZABBIX INFO"

_CHECK_PKG "(zabbix)" "Pacotes do Serviço Zabbix"

_CHECK_FILE "/etc/zabbix/zabbix_server.conf" "Arquivos de Configuração do Servidor Zabbix"

_CHECK_FILE "/etc/zabbix/apache.conf" "Arquivos de Configuração do Apache para o Servidor Zabbix"

_CHECK_FILE "/etc/zabbix/web/zabbix.conf.php" "Arquivos de Configuração da conexão com o Banco para o Servidor Zabbix"

_CHECK_FILE "/etc/zabbix/zabbix_agentd.conf" "Arquivos de Configuração Cliente Zabbix"

_CHECK_DIR "/etc/zabbix/zabbix_agentd.d" "Arquivos de Configuração Adicionais do Zabbix" "*.conf" 

### FOOTER
_FWARNING "GENERATING ZABBIX INFO"

}


_APACHE(){

### HEADER
_HWARNING "GENERATING APACHE INFO"

_CHECK_PKG "(^http|^php|php[5]?|apache[2]?)" "Pacotes dos Serviços Apache e PHP"

_CHECK_FILE "/etc/apache2/apache2.conf" "Arquivos de Configuração do Apache"

_CHECK_FILE "/etc/httpd/conf/httpd.conf" "Arquivos de Configuração do Apache"

_CHECK_DIR "/etc/apache2" "Arquivos de Configuração Adicionais do Apache" "*.conf"

_CHECK_DIR "/etc/httpd/conf.d" "Arquivos de Configuração Adicionais do Apache" "*.conf"  

_CHECK_DIR "/etc/apache2/sites-enabled" "Arquivos de Configuração Adicionais do Apache"

_CHECK_CMD "${APACHECTL} -t -D DUMP_MODULES" "Módulos utilizados pelo Apache" "" "${APACHECTL}"

_CHECK_CMD "${TREE} -d -L 5 /var/www" "Estrutura de diretórios de sites (/var/www/)" "/var/www" "${TREE}"

_CHECK_CMD "${TREE} -d -L 5 /var/chroot/var/www/website" "Estrutura de diretórios de sites (/var/chroot/var/www/website)" "/var/chroot/var/www/website" "${TREE}"

_CHECK_FILE "/etc/php.ini" "Arquivos de Configuração do PHP"

_CHECK_FILE "/etc/php5/apache2/php.ini" "Arquivos de Configuração do PHP"

_CHECK_FILE "/etc/php5/cli/php.ini" "Arquivos de Configuração do Cliente PHP"

### FOOTER
_FWARNING "GENERATING APACHE INFO"

}


_BIND () {

### HEADER
_HWARNING "GENERATING BIND INFO"

_CHECK_PKG "(bind9|^bind)" "Pacotes do Serviço de DNS"

_CHECK_FILE "/etc/default/bind9" "Arquivos de Configuração do Serviço do Bind"

_CHECK_DIR "${BIND_BASE}/etc/bind" "Definições de configuração do Servidor Bind" "named.conf* rndc.*"

_CHECK_DIR "${BIND_BASE}/etc/bind" "Definições da chave RNDC do Servidor Bind" "rndc.*"

_CHECK_DIR "${BIND_BASE}/etc/bind" "Definições de zonas locais do Servidor Bind" "db.*"

_CHECK_DIR "${BIND_BASE}/etc/bind/zones/internal" "Definições das Zonas da View Interna do Servidor Bind" "named.conf.*"

_CHECK_DIR "${BIND_BASE}/etc/bind/zones/external" "Definições das Zonas View Externa do Servidor Bind" "named.conf.*"

_CHECK_DIR "${BIND_BASE}/etc/bind/zones/disabled" "Definições das Zonas Desabilitadas do Servidor Bind" "named.conf.*"

_CHECK_DIR "${BIND_BASE}/var/cache/bind/master" "Definições dos DB das Zonas Master do Servidor Bind" "db.*"

_CHECK_DIR "${BIND_BASE}/var/cache/bind/slave" "Definições dos DB das Zonas Slave do Servidor Bind" "db.*"

_CHECK_DIR "${BIND_BASE}/var/cache/bind/disabled" "Definições dos DB das Zonas Desabilitadas do Servidor Bind" "db.*"

_CHECK_DIR "${BIND_BASE2}/etc" "Definições de configuração do Servidor Bind" "named.conf* rndc.*"

_CHECK_DIR "${BIND_BASE2}/var/named" "Definições de zonas locais do Servidor Bind" "named.*"

_CHECK_CMD "${TREE} -d -L 5 ${BIND_BASE}" "Estrutura de diretórios do Bind" "${BIND_BASE}" "" "${TREE}"

_CHECK_CMD "${TREE} -d -L 5 ${BIND_BASE2}" "Estrutura de diretórios do Bind" "${BIND_BASE2}" "" "${TREE}"

### FOOTER
_FWARNING "GENERATING BIND INFO"

}

_OPENVPN(){

### HEADER
_HWARNING "GENERATING OPENVPN INFO"

_CHECK_PKG "(openvpn)" "Pacotes do Serviço OpenVPN"

_CHECK_DIR "/etc/openvpn" "Arquivos de Configuração do Servidor OpenVPN" "*.conf"

_CHECK_DIR "/etc/openvpn/certs" "Arquivos de Certificados dos Clientes do Servidor OpenVPN" "*.crt"

_CHECK_DIR "/etc/openvpn/keys" "Arquivos de Keys dos Clientes do Servidor OpenVPN" "*.key"

_CHECK_DIR "/etc/openvpn/ccd" "Arquivos de Rotas dos Clientes do Servidor OpenVPN"

_CHECK_CMD "${TREE} -d -L 5 /etc/openvpn" "Estrutura de diretórios do Bind" "/etc/openvpn" "" "${TREE}"

### FOOTER
_FWARNING "GENERATING OPENVPN INFO"

}

_EJABBERD(){

### HEADER
_HWARNING "GENERATING EJABBERD INFO"

_CHECK_PKG "(jabber)" "Pacotes do Serviço Ejabber"

_CHECK_DIR "/etc/ejabberd" "Arquivos de Configuração do Servidor Ejabber" "*.cfg"

_CHECK_DIR "/etc/ejabberd" "Arquivos de Certificados do Servidor Ejabber" "*.pem"

_CHECK_FILE "/etc/ejabberd/inetrc" "Arquivo de Configurações Adicionais do Servidor Ejabber"

_CHECK_CMD "${TREE} -d -L 5 /etc/ejabberd" "Estrutura de diretórios do Ejabber" "/etc/ejabberd" "" "${TREE}"

### FOOTER
_FWARNING "GENERATING EJABBERD INFO"

}



_SYSLOG () {

### HEADER
_HWARNING "GENERATING SYSLOG INFO"

_CHECK_PKG "(syslog)" "Pacotes do Serviço Rsyslog"

_CHECK_FILE "/etc/rsyslog.conf" "Arquivos de Configuração do Rsyslog"

_CHECK_DIR "/etc/rsyslog.d" "Arquivos de Configuração Adicionais do Rsyslog"

### FOOTER
_FWARNING "GENERATING SYSLOG INFO"

}

_LOGROTATE(){

### HEADER
_HWARNING "GENERATING LOGROTATE INFO"

_CHECK_PKG "(logrotate)" "Pacotes do Serviço LogRotate"

_CHECK_FILE "/etc/logrotate.conf" "Arquivos de Configuração do LogRotate"

_CHECK_DIR "/etc/logrotate.d" "Arquivos de Configuração Adicionais do Rsyslog"

### FOOTER
_FWARNING "GENERATING LOGROTATE INFO"

}

_SSH () {

### HEADER
_HWARNING "GENERATING SSH INFO"

_CHECK_PKG "(ssh)" "Pacotes do Serviço SSH"

_CHECK_DIR "/etc/ssh" "Arquivos de Configuração do Serviço SSH" "ssh*_config"

### FOOTER
_FWARNING "GENERATING SSH INFO"

}

_SNMP () {

### HEADER
_HWARNING "GENERATING SNMP INFO"

_CHECK_PKG "(snmp)" "Pacotes do Serviço SNMP"

_CHECK_FILE "/etc/snmp/snmpd.conf" "Arquivos de Configuração do Servidor SNMP"

_CHECK_FILE "/etc/snmp/snmp.conf" "Arquivos de Configuração do Cliente SNMP"

### FOOTER
_FWARNING "GENERATING SNMP INFO"

}

_VSFTPD () {

### HEADER
_HWARNING "GENERATING VSFTPD INFO"

_CHECK_PKG "(vsftp)" "Pacotes do Serviço VSFTP"

_CHECK_FILE "/etc/vsftpd.*" "Arquivos de Configuração do Servidor VSFTPD"

_CHECK_DIR "/etc/vsftpd" "Arquivos de Configuração Adicionais do VSFTPD"

### FOOTER
_FWARNING "GENERATING VSFTPD INFO"

}

_PROFTPD() {

### HEADER
_HWARNING "GENERATING PROFTPD INFO"

_CHECK_PKG "(proftp)" "Pacotes do Serviço ProFTP"

_CHECK_DIR "/etc/proftpd" "Arquivos de Configuração do Servidor ProFTP" "*.[pc]*" 

_CHECK_DIR "/etc/proftpd/conf.d" "Arquivos de Configuração Adicionais do Servidor ProFTP" "*.conf" 

### FOOTER
_FWARNING "GENERATING PROFTPD INFO"

}


_CUPS() {

### HEADER
_HWARNING "GENERATING CUPS INFO"

_CHECK_PKG "(cups)" "Pacotes do Serviço CUPS"

_CHECK_FILE "/etc/default/cups" "Arquivos de Configuração do Serviço CUPS"

_CHECK_DIR "/etc/cups" "Arquivos de Configuração do Servidor CUPS" "*.conf" 

_CHECK_DIR "/etc/cups/ssl" "Arquivos de Certificados do CUPS" "*.[pk]*" 

### FOOTER
_FWARNING "GENERATING CUPS INFO"

}


_IPTABLES () {

### HEADER
_HWARNING "GENERATING IPTABLES INFO"

_CHECK_PKG "(iptables|iproute)" "Pacotes do IPtables e IProute"

_CHECK_FILE "/etc/init.d/rc.firewall" "Arquivo de Configuração do Firewall"

_CHECK_DIR "/etc/firewall" "Arquivos de Configuração Adicionais do Firewall"

### FOOTER
_FWARNING "GENERATING IPTABLES INFO"

}

_FAIL2BAN(){

### HEADER
_HWARNING "GENERATING FAIL2BAN INFO"

_CHECK_PKG "(fail2ban)" "Pacotes do Fail2Ban"

_CHECK_DIR "/etc/fail2ban" "Arquivos de Configuração do Fail2Ban"

_CHECK_DIR "/etc/fail2ban/action.d" "Arquivos de Configuração das Ações do Fail2Ban"

_CHECK_DIR "/etc/fail2ban/filter.d" "Arquivos de Configuração dos Filtros do Fail2Ban"

### FOOTER
_FWARNING "GENERATING FAIL2BAN INFO"

}


_CRONTAB () {

### HEADER
_HWARNING "GENERATING CRONTAB INFO"

_CHECK_PKG "(cron)" "Pacotes do Serviço Crontab"

_CHECK_FILE "/etc/crontab" "Arquivo de Configuração do Cron para o sistema"

_CHECK_DIR "/etc/cron.d" "Agendamentos para o Sistema" 

_CHECK_DIR "/etc/cron.hourly" "Agendamentos para serem executados a cada hora para o Sistema"

_CHECK_DIR "/etc/cron.daily" "Agendamentos para serem executados diariamente para o Sistema"  

_CHECK_DIR "/etc/cron.weekly" "Agendamentos para serem executados semanalmente para o Sistema"

_CHECK_DIR "/etc/cron.monthly" "Agendamentos para serem executados mensalmente para o Sistema"  

_CHECK_DIR "/var/spool/cron" "Arquivos de Configuração do Cron para usuários" 

_CHECK_DIR "/var/spool/cron/crontabs" "Arquivos de Configuração do Cron"

### FOOTER
_FWARNING "GENERATING CRONTAB INFO"

}

_XINETD() {

### HEADER
_HWARNING "GENERATING XINETD INFO"

_CHECK_PKG "(xinet)" "Pacotes do Serviço Xinetd"

_CHECK_FILE "/etc/xinetd.conf" "Arquivo de Configuração do Xinetd"

_CHECK_DIR "/etc/xinetd.d" "Arquivos de Configuração do Xinetd"

### FOOTER
_FWARNING "GENERATING XINETD INFO"

}



_MYSQL () {

### HEADER
_HWARNING "GENERATING MYSQL INFO"

_CHECK_PKG "(mysql)" "Pacotes do Serviço MySQL"

_CHECK_DIR "/etc/mysql" "Arquivos de Configuração do MySQL"

_CHECK_FILE "/etc/my.cnf" "Arquivo de Configuração do MySQL"

_CHECK_DIR "/etc/mysql/conf.d" "Arquivos de Configuração Adicionais do MySQL"

_CHECK_CMD "${TREE} -d -L 5 /var/lib/mysql" "Estrutura de diretórios do MySQL" "/var/lib/mysql" "${TREE}"

### FOOTER
_FWARNING "GENERATING MYSQL INFO"

}

_POSTGRESQL() {

### HEADER
_HWARNING "GENERATING POSTGRESQL INFO"

_CHECK_PKG "(postgre|pgsql)" "Pacotes do Serviço PostgreSQL"

_CHECK_DIR "/etc/postgresql/[0-9].[0-9]/main" "Arquivos de Configuração do PostgreSQL" "*.conf"

_CHECK_CMD "${TREE} -d -L 5 /var/lib/postgresql/[0-9].[0-9]/main/base" "Estrutura de diretórios do PostgreSQL" "/var/lib/postgresql/[0-9].[0-9]/main/base" "${TREE}"

### FOOTER
_FWARNING "GENERATING POSTGRESQL INFO"

}


_CLAMAV () {

### HEADER
_HWARNING "GENERATING CLAMAV INFO"

_CHECK_PKG "(clam)" "Pacotes do Serviço ClamAV"

_CHECK_DIR "/etc/clamav" "Arquivos de Configuração do Servidor ClamAV" "*.conf" 

### FOOTER
_FWARNING "GENERATING CLAMAV INFO"

}

_AMAVIS () {

### HEADER
_HWARNING "GENERATING AMAVIS INFO"

_CHECK_PKG "(amavis)" "Pacotes do Serviço Amavis"

_CHECK_DIR "/etc/amavis/conf.d" "Arquivos de Configuração do Servidor Amavis" "*.conf" 

### FOOTER
_FWARNING "GENERATING AMAVIS INFO"

}

_SPAMASSASSIN () {

### HEADER
_HWARNING "GENERATING SPAMASSASSIN INFO"

_CHECK_FILE "/etc/default/spamassassin" "Arquivos de Configuração do Serviço SpamAssassin"

_CHECK_PKG "(spamassassin|spamc)" "Pacotes do Serviço SpamAssassin"

_CHECK_DIR "/etc/spamassassin" "Arquivos de Configuração do Serviço SpamAssassin" "*.cf"

_CHECK_DIR "/etc/spamassassin" "Arquivos de Configuração Adicionais do Serviço SpamAssassin" "*.pre"  

### FOOTER
_FWARNING "GENERATING SPAMASSASSIN INFO"

}

_CACTI () {

### HEADER
_HWARNING "GENERATING CACTI INFO"

_CHECK_PKG "(cacti)" "Pacotes do Serviço Cacti"

_CHECK_DIR "/etc/cacti" "Arquivos de Configuração do Serviço do Cacti" 

### FOOTER
_FWARNING "GENERATING CACTI INFO"

}

_NAGIOS () {

### HEADER
_HWARNING "GENERATING NAGIOS INFO"

_CHECK_PKG "(nagios)" "Pacotes do Serviço Nagios"

_CHECK_DIR "/etc/nagios3/" "Arquivos de Configuração do Serviço do Nagios 3"  "*.c[of]*"

_CHECK_FILE "/etc/nagios3/htpasswd.users" "Usuários com acesso ao Painel Web"

### FOOTER
_FWARNING "GENERATING NAGIOS INFO"

}

_POSTFIX () {

### HEADER
_HWARNING "GENERATING POSTFIX INFO"

_CHECK_PKG "(postfix)" "Pacotes do Serviço Postfix"

_CHECK_DIR "/etc/postfix" "Arquivos de Configuração do Servidor Postfix"  "*.cf"

_CHECK_FILE "/etc/postfix/aliases" "Configuração de Alias Locais do Postfix"

_CHECK_DIR "/etc/postfix/ssl" "Configuração de SSL do Postfix" "*.[pck]*"

_CHECK_FILE "/etc/pam.d/smtp" "Configuração da PAM para o Serviço de SMTP"

_CHECK_FILE "/etc/pam.d/pop" "Configuração da PAM para o Serviço de POP"

_CHECK_FILE "/etc/pam.d/pop" "Configuração da PAM para o Serviço de IMAP"

_CHECK_FILE "/var/www/postfixadmin/config.inc.php" "Configuração do PostfixAdmin"

_CHECK_CMD "${TREE} -d -L 5 /srv/vmail" "Estrutura de diretórios do Vmail" "/srv/vmail" "${TREE}"

### FOOTER
_FWARNING "GENERATING POSTFIX INFO"

}

_ZIMBRA () {

### HEADER
_HWARNING "GENERATING ZIMBRA INFO"

_CHECK_PKG "(zimbra)" "Pacotes do Serviço Postfix"

_CHECK_CMD "su - zimbra -c 'zmcontrol status'" "Status do Zimbra" "/srv/vmail" "su"

_CHECK_FILE "/opt/zimbra/config.*" "Configuração do Servidor Zimbra"

_CHECK_DIR "/opt/zimbra/postfix/conf" "Arquivos de Configuração do Servidor Postfix para o Zimbra"  "*.cf"

_CHECK_FILE "/opt/zimbra/postfix/conf/aliases" "Configuração de Alias Locais do Postfix para o Zimbra"

_CHECK_DIR "/opt/zimbra/conf" "Configuração do SSL do Postfix para o Zimbra" "smtpd.*"

_CHECK_DIR "/opt/zimbra/conf/zmconfigd" "Configurações Adicionais para do Postfix para o Zimbra" "*.cf"

_CHECK_DIR "/opt/zimbra/conf" "Configuração do Amavis para o Zimbra" "amavis.*"

_CHECK_DIR "/opt/zimbra/conf" "Configuração do ClamAV para o Zimbra" "*clam*"

_CHECK_DIR "/opt/zimbra/conf" "Configuração do Ldap para o Zimbra" "ldap*"

_CHECK_DIR "/opt/zimbra/conf" "Chaves de Cryptografia do Ldap para o Zimbra" "slapd.*"

_CHECK_FILE "/opt/zimbra/conf/my.cnf" "Configuração do MySQL para o Zimbra"

_CHECK_FILE "/opt/zimbra/conf/nginx.conf" "Configuração do Nginx para o Zimbra"

_CHECK_DIR "/opt/zimbra/conf/nginx/includes" "Configuração extra do Nginx para o Zimbra" "nginx.*"

_CHECK_DIR "/opt/zimbra/conf" "Chaves de Cryptografia para do Nginx para o Zimbra" "nginx.[ck]*"

_CHECK_FILE "/opt/zimbra/conf/php.ini" "Configuração do PHP para o Zimbra"

_CHECK_DIR "/opt/zimbra/conf" "Configuração do OpenDkim para o Zimbra" "opendkim*"

_CHECK_DIR "/opt/zimbra/conf" "Configuração do Saslauthd para o Zimbra" "saslauthd*"

_CHECK_DIR "/opt/zimbra/conf/sasl2" "Configuração extra do Saslauthd para o Zimbra" "smtpd*"

_CHECK_FILE "/opt/zimbra/conf/zimbra.ld.conf" "Configuração das Bibliotecas para o Zimbra"

_CHECK_FILE "/opt/zimbra/conf/zmconfigd.cf" "Configuração das Variáveis de ambiente para o Zimbra"

_CHECK_FILE "/opt/zimbra/conf/zmconfigd.log4j.properties" "Configuração dos Logs do Java para o Zimbra"

_CHECK_FILE "/opt/zimbra/conf/zmlogrotate" "Configuração do logrotate para o Zimbra"

_CHECK_CMD "${TREE} -d -L 5 /opt/zimbra" "Estrutura de diretórios do Vmail" "/opt/zimbra" "${TREE}"

### FOOTER
_FWARNING "GENERATING ZIMBRA INFO"

}


_ISOQLOG(){

### HEADER
_HWARNING "GENERATING ISOQLOG INFO"

_CHECK_PKG "(isoqlog)" "Pacotes do Isoqlog"

_CHECK_DIR "/etc/isoqlog" "Arquivos de Configuração do Isoqlog"

### FOOTER
_FWARNING "GENERATING FAIL2BAN INFO"

}



_SASL(){

### HEADER
_HWARNING "GENERATING SASL INFO"

_CHECK_PKG "(sasl)" "Pacotes do Serviço SASL Auth"

_CHECK_DIR "/etc/postfix/sasl" "Configuração de SASL Auth" "*.conf"

_CHECK_FILE "/etc/default/saslauthd" "Configuração do Serviço SASL Auth"

### FOOTER
_FWARNING "GENERATING SASL INFO"

}

_COURIER () {

### HEADER
_HWARNING "GENERATING COURIER INFO"

_CHECK_PKG "(courier)" "Pacotes do Serviço Courier"

_CHECK_DIR "/etc/courier" "Arquivos de Configuração de Autenticação do Courier"  "auth*"

_CHECK_DIR "/etc/courier" "Arquivos de Configuração do IMAP no Courier"  "imapd*"

_CHECK_DIR "/etc/courier" "Arquivos de Configuração do POP3 no Courier"  "pop3d*"

### FOOTER
_FWARNING "GENERATING COURIER INFO"

}

_SQUID () {

### HEADER
_HWARNING "GENERATING SQUID INFO"

_CHECK_PKG "(squid)" "Pacotes do Serviço SQUID"

_CHECK_DIR "/etc/squid" "Arquivos de Configuração do Squid"  "*.conf"

_CHECK_DIR "/etc/squid/regras" "Arquivos de Configuração das Regras do Squid"

_CHECK_DIR "/etc/squid3" "Arquivos de Configuração do Squid 3"  "*.conf"

_CHECK_DIR "/etc/squid3/regras" "Arquivos de Configuração das Regras do Squid 3"

_CHECK_CMD "${TREE} -d -L 5 /etc/squid" "Estrutura de diretórios do Squid" "/etc/squid" "${TREE}"

_CHECK_CMD "${TREE} -d -L 5 /etc/squid3" "Estrutura de diretórios do Squid 3" "/etc/squid3" "${TREE}"

_CHECK_FILE "/etc/squid3/passwd" "Controle de usuário e senha Locais"

### FOOTER
_FWARNING "GENERATING SQUID INFO"

}

_SARG(){

### HEADER
_HWARNING "GENERATING SARG INFO"

_CHECK_PKG "(sarg)" "Pacotes do Serviço SARG"

_CHECK_DIR "/etc/sarg" "Arquivos de Configuração do Sarg"  "*.conf"

_CHECK_CMD "${TREE} -d -L 5 /var/www/sarg" "Estrutura de diretórios do Sarg" "/var/www/sarg" "${TREE}"

### FOOTER
_FWARNING "GENERATING SARG INFO"

}

_SVN(){

### HEADER
_HWARNING "GENERATING SVN INFO"

_CHECK_PKG "(subversion)" "Pacotes do Serviço SVN"

_CHECK_FILE "/var/www/svn/authz" "Arquivos de Controle de Grupos e Usuários do SVN"

_CHECK_FILE "/srv/svn/svnauthz" "Arquivos de Controle de Grupos e Usuários do SVN"

_CHECK_CMD "${TREE} -d -L 5 /var/www/svn" "Estrutura de diretórios do SVN" "/var/www/svn" "${TREE}"

_CHECK_CMD "${TREE} -d -L 5 /srv/svn" "Estrutura de diretórios do SVN" "/srv/svn" "${TREE}"

### FOOTER
_FWARNING "GENERATING SVN INFO"

}

_TRAC(){

### HEADER
_HWARNING "GENERATING TRAC INFO"

if [ -d /srv/trac ]; then
echo "<hr />" >> ${DOC}
echo "<h1> Informações do Serviço TRAC </h1>" >> ${DOC}

_CHECK_CMD "${TREE} -d -L 5 /srv/trac" "Estrutura de diretórios do TRAC" "/srv/trac" "${TREE}"

fi

### FOOTER
_FWARNING "GENERATING TRAC INFO"

}


### Function to execute all function or only one
_EXEC(){

### Define the value to a function
FUNC="$1"

if [ -z "${FUNC}" ]; then
	### Don't change the order the follow five functions.
	_SET_VAR
	_INIT
	_SET_VAR
	_WARNING
	_FILE_HEADER
	## Don't change the order the five functions bellow.
	_SYSTEM_INFO
	_HARDWARE
	_BOOT
	_REDE
	_ISCSI
	_INSTALLED_PKG
	_NFS
	_SAMBA
	_LDAP
	_PAM
	_BACULA
	_ZABBIX
	_APACHE
	_BIND
	_OPENVPN
	_SYSLOG
	_LOGROTATE
	_SSH
	_SNMP
	_VSFTPD
	_PROFTPD
	_CUPS
	_IPTABLES
	_FAIL2BAN
	_CRONTAB
	_MYSQL
	_XINETD
	_POSTGRESQL
	_EJABBERD
	_CLAMAV
	_AMAVIS
	_SPAMASSASSIN
	_CACTI
	_NAGIOS
	_POSTFIX
	_ZIMBRA
	_ISOQLOG
	_SASL
	_COURIER
	_SQUID
	_SARG
	_SVN
	_TRAC
### Footer to the html
	_FOOTER
else
	### Don't change the order the follow five functions.
	_SET_VAR
	_INIT
	_SET_VAR
	_WARNING
	_FILE_HEADER
	## Don't change the order the five functions bellow.
	### Execute the follow functions as requested
	for END in ${FUNC}
	do
	### Check if the function exists or not
	CHECK=$(${TYPE} -t ${END})
	if [ ! -z ${CHECK} ]; then
	${END}
	fi
	done
### Footer to the html
	_FOOTER
fi

}

### Call all function if the value is empty or call only one if the value is not empty
_EXEC ""

echo
echo -e "${GREEN} DOCUMENTATION GENERATED SUCESSFULL.${CLOSE}"
echo -e "${GREEN} IT CAN BE DISPLAYED AT: ${CLOSE} ${RED} ${DOC} ${CLOSE}"
echo

#scp -P 22022 $(hostname).html root@172.17.0.198:/srv/Documentation/
