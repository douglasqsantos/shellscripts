@echo off

echo "Criando a estrutura de diretorios para o Zabbix"
mkdir "%ProgramFiles%\Zabbix\logs"

echo "Copiando arquivos do Zabbix"
copy /Y bin\win32\* "%ProgramFiles%\Zabbix\"
copy /Y conf\zabbix_agentd.win.conf "%ProgramFiles%\Zabbix\"

echo "Instalando o Zabbix como servico"
"%ProgramFiles%\Zabbix\zabbix_agentd.exe" -i -c "%ProgramFiles%\Zabbix\zabbix_agentd.win.conf"

echo "Criando regra de liberacao de acesso ao Servidor"
netsh advfirewall firewall add rule name="Zabbix Agentd" dir=in action=allow protocol=TCP localport=10050

echo "Iniciando o servico do Zabbix"
net start "Zabbix Agent"

REM  para remover o cliente va em services.msc e pare o serviço e veja a linha de comando da instalação algo como
REM "%ProgramFiles%\Zabbix\zabbix_agentd.exe" -c "%ProgramFiles%\Zabbix\zabbix_agentd.win.conf" pare remove use
REM "%ProgramFiles%\Zabbix\zabbix_agentd.exe" -c "%ProgramFiles%\Zabbix\zabbix_agentd.win.conf" -d




