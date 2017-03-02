@echo off

echo "Copiando arquivos do Bacula"
move /Y "C:\Program Files\Bacula\bacula-fd.conf" "C:\Program Files\Bacula\bacula-fd.conf.bkp"
move /Y "C:\Program Files\Bacula\bconsole.conf" "C:\Program Files\Bacula\bconsole.conf.bkp"
xcopy confs\* "C:\Program Files\Bacula\" /s /y


echo "Importando registro para o Bacula"
regedit.exe /s bacula.reg

echo "Criando regra de liberacao de acesso ao Servidor"
netsh advfirewall firewall add rule name="Bacula-FD" dir=in action=allow protocol=TCP localport=9102

echo "Habilitando o Servico de deteccao de sevicos interativos"
sc config UI0Detect start= auto

echo "Inicializando o Servico de deteccao de sevicos interativos"
net start "UI0Detect"

echo "Iniciando o servico do Bacula"
net start "Bacula-fd"
