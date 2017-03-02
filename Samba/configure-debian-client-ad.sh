#!/bin/bash
APTITUDE="/usr/bin/aptitude"
PACOTES="samba samba-common smbclient winbind krb5-config libpam-krb5 krb5-user libsasl2-modules-gssapi-mit ssh-krb5"
CAT="/bin/cat"
CD="cd"
CP="/bin/cp"
RM="/bin/rm"
CLIENT=$(hostname)
PDC="10.0.0.248"
NTPDATE="/usr/sbin/ntpdate"
DOMAIN="domain.local"
GROUP=$(echo ${DOMAIN} | cut -d "." -f 1 | tr "a-z" "A-Z")
UDOMAIN=$(echo ${DOMAIN} | tr "a-z" "A-Z")
UHOSTNAME=$(hostname | tr "a-z" "A-Z")
GREEN="\033[01;32m" RED="\033[01;31m" YELLOW="\033[01;33m" CLOSE="\033[m"
APTITUDE="/usr/bin/aptitude"
SED="/bin/sed"
NET="/usr/bin/net"
USER="douglas"
USERS="nerso douglas"
PASSWORD=""
WBINFO="/usr/bin/wbinfo"
GETENT="/usr/bin/getent"
GPASSWD="/usr/bin/gpasswd"
FQDN_PDC="pdc.domain.local"

${APTITUDE} update || { echo "${RED}FALHA AO ATUALIZAR O APTITUDE ${CLOSE}"; exit 1; }

export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive
${APTITUDE} install ${PACOTES} -y || { echo "${RED}FALHA AO INSTALAR DEPENDENCIAS ${CLOSE}"; exit 1; }
unset DEBIAN_PRIORITY
unset DEBIAN_FRONTEND

${CP} -Rfa /etc/resolv.conf{,.bkp}

${CAT} << EOF > /etc/resolv.conf
search ${DOMAIN}
domain ${DOMAIN}
nameserver ${PDC}
EOF

${NTPDATE} -u ${PDC}

${CP} -Rfa /etc/krb5.conf{,.bkp}

${CAT} << EOF > /etc/krb5.conf
[libdefaults]
       default_realm = ${UDOMAIN}
       krb4_config = /etc/krb.conf
       krb4_realms = /etc/krb.realms
       kdc_timesync = 1
       ccache_type = 4
       forwardable = true
       proxiable = true
       v4_instance_resolve = false
       fcc-mit-ticketflags = true
       default_keytab_name = FILE:/etc/krb5.keytab
v4_name_convert = {
host = {
       rcmd = host
       ftp = ftp
}
plain = {
       something = something-else
}
}
        fcc-mit-ticketflags = true
[realms]
${UDOMAIN} = {
        kdc = ${PDC}
        admin_server = ${PDC}:749
        default_server = ${PDC}
}
[domain_realm]
        .${DOMAIN} = ${UDOMAIN}
        ${DOMAIN}  = ${UDOMAIN}
[login]
        krb4_convert = true
        krb4_get_tickets = false
[kdc]
        profile = /etc/krb5kdc/kdc.conf
[appdefaults]
pam = {
        realm = ${UDOMAIN}
        ticket_lifetime = 1d
        renew_lifetime = 1d
        forwardable = true
        proxiable = false
        retain_after_close = false
        minimum_uid = 1000
        try_first_pass = true
        ignore_root = true
        debug = false
}
[logging]
        default = file:/var/log/krb5libs.log
        kdc = file:/var/log/krb5kdc.log
        admin_server = file:/var/log/kadmind.log
EOF

${CAT} << EOF >> /etc/security/limits.conf
#colocar no final do arquivo
root hard nofile 131072
root soft nofile 65536
mioutente hard nofile 32768
mioutente soft nofile 16384
EOF

${CP} -Rfa /etc/samba/smb.conf{,.bkp}

${CAT} << EOF > /etc/samba/smb.conf
[global]
	workgroup = ${GROUP}
	realm = ${UDOMAIN}
	netbios name = ${UHOSTNAME}
	server string = ${UHOSTNAME}
	security = ADS
	auth methods = winbind
    kerberos method = secrets and keytab
    winbind refresh tickets = yes
	socket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192
	load printers = No
	printing = bsd
    printcap name = /dev/null
	disable spoolss = Yes
	local master = No
	domain master = No
	winbind cache time = 15
	winbind enum users = Yes
	winbind enum groups = Yes
	winbind use default domain = Yes
	idmap config * : range = 10000-30000
	idmap config * : backend = tdb
    template shell = /bin/bash
	template homedir = /home/%U
EOF

${CP} /etc/nsswitch.conf{,.bkp}

${CAT} << EOF >  /etc/nsswitch.conf
passwd:         compat winbind
group:          compat winbind
shadow:         compat

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF

${CP} -Rfa /etc/pam.d/common-account{,.bkp}

${CAT} << EOF > /etc/pam.d/common-account
#/etc/pam.d/common-account
account	[success=2 new_authtok_reqd=done default=ignore]	pam_unix.so 
account	[success=1 new_authtok_reqd=done default=ignore]	pam_winbind.so 
account	requisite			pam_deny.so
account	required			pam_permit.so
account	required			pam_krb5.so minimum_uid=1000
EOF

${CP} -Rfa /etc/pam.d/common-auth{,.bkp}
${CAT} << EOF > /etc/pam.d/common-auth
#/etc/pam.d/common-auth
auth	[success=3 default=ignore]	pam_krb5.so minimum_uid=1000
auth	[success=2 default=ignore]	pam_unix.so nullok_secure try_first_pass
auth	[success=1 default=ignore]	pam_winbind.so krb5_auth krb5_ccache_type=FILE cached_login try_first_pass
auth	requisite			pam_deny.so
auth	required			pam_permit.so
EOF

${CP} -Rfa /etc/pam.d/common-password{,.bkp}
${CAT} << EOF > /etc/pam.d/common-password
#/etc/pam.d/common-password
password	[success=3 default=ignore]	pam_unix.so obscure use_authtok try_first_pass sha512
password	[success=2 default=ignore]	pam_krb5.so minimum_uid=1000
password	[success=1 default=ignore]	pam_winbind.so use_authtok try_first_pass
password	requisite			pam_deny.so
password	required			pam_permit.so
EOF


${CP} -Rfa /etc/pam.d/common-session{,.bkp}
${CAT} << EOF > /etc/pam.d/common-session
#/etc/pam.d/common-session
session	[default=1]			pam_permit.so
session	requisite			pam_deny.so
session	required			pam_permit.so
session	required	        pam_unix.so
session	optional			pam_krb5.so minimum_uid=1000
session	optional			pam_winbind.so
session optional            pam_mkhomedir.so skel=/etc/skel umask=077
EOF

${CP} -Rfa /etc/pam.d/sshd{,.bkp}
${CAT} << EOF > /etc/pam.d/sshd
#/etc/pam.d/sshd
auth       required     pam_env.so # [1]
auth       required     pam_env.so envfile=/etc/default/locale
@include common-auth
account    required     pam_nologin.so
account    sufficient   pam_succeed_if.so user ingroup root
account    requisite    pam_succeed_if.so user ingroup sudo
@include common-account
@include common-session
session    optional     pam_motd.so  motd=/run/motd.dynamic noupdate
session    optional     pam_motd.so # [1]
session    optional     pam_mail.so standard noenv # [1]
session    required     pam_limits.so
@include common-password
EOF

${CP} -Rfa /etc/pam.d/login{,.bkp}
${CAT} << EOF > /etc/pam.d/login
#/etc/pam.d/login
auth       optional   pam_faildelay.so  delay=3000000
auth [success=ok new_authtok_reqd=ok ignore=ignore user_unknown=bad default=die] pam_securetty.so
auth       requisite  pam_nologin.so
account    sufficient   pam_succeed_if.so user ingroup root
account    requisite    pam_succeed_if.so user ingroup sudo
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session       required   pam_env.so readenv=1
session       required   pam_env.so readenv=1 envfile=/etc/default/locale
@include common-auth
auth       optional   pam_group.so
session    required   pam_limits.so
session    optional   pam_lastlog.so
session    optional   pam_motd.so  motd=/run/motd.dynamic
session    optional   pam_motd.so
session    optional   pam_mail.so standard
@include common-account
@include common-session
@include common-password
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
EOF

/etc/init.d/samba restart
/etc/init.d/winbind restart

${NET} ads join -D ${DOMAIN} createupn=host/$(hostname -f)@DOMAIN.LOCAL -U ${USER}%${PASSWORD} -S ${FQDN_PDC} 
#chmod 664 /etc/krb5.keytab
#${NET} ads keytab create -k

/etc/init.d/samba restart
/etc/init.d/winbind restart

#${NET} ads testjoin
#${NET} ads info
#${WBINFO} -u
#${WBINFO}  -g
#${GETENT} passwd
#${GETENT} group 

for END in ${USERS}; do
${GPASSWD} -a ${END} sudo
done


#
#kinit
#net ads leave -U douglas
#net ads join createupn=host/scisjplwiki.domain.local@DOMAIN.LOCAL -S disprosio.domain.local -k
#net ads keytab add host/atusjpldns01.domain.local@DOMAIN.LOCAL
#date +%T -s "08:46:25"
#kinit
#net ads leave -U douglas
#net ads join createupn=host/atusjpldns01.domain.local@DOMAIN.LOCAL -S disprosio.domain.local -k
#net ads keytab add host/scisjplwiki.domain.local@DOMAIN.LOCAL
#
#The above net ads join command creates the server in the container
#"OU=Servers,OU=Sydney,OU=Australia,OU=Asiapac,DC=EXAMPLENET,DC=ORG"
# net ads join -U skwok@EXAMPLENET.ORG createcomputer="Asiapac/Australia/Sydney/Servers"
#net ads join createupn=host/atusjpldns01.domain.local@DOMAIN.LOCAL -S disprosio.domain.local -k
#net ads leave -U douglas
#net ads join -D domain.local createupn=host/mint.domain.local@DOMAIN.LOCAL -U douglas -S disprosio.domain.local -I 10.0.0.248 -d 10
#net ads join -D domain.local createupn=host/mint.domain.local@DOMAIN.LOCAL -U douglas -I 10.0.0.248

kinit douglas << EOF
$SENHA
EOF
