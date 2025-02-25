--Understanding Database Architecture with Oracle

--Globalmantics

--Video Configuring the repos for Centos
su -
yum -y install httpd


--si la commande precedente remonte des erreur o va nettoyer le yum repos
cd /etc/yum.repos.d/
rm -rf*
wget https://agabyte19.github.io/udawo/oel8.repo
cat oel8.repo

--installation des packages de nouveau
yum -y install httpd


--Video Installing Oracle Database 19c on Linux
su -

ifconfig | head 

hostname

--avec ces deux commande recupérer inet et l'assicier au hostname
echo '<inet> <name perso> <hostname>' >> /etc/hosts

--On verifie 
cat /etc/hosts
ping -c4 <hostname>

--Next step : voir nombre packages insallé 
rpm -qa | wc -l

--pour voir si oracle est isnstallé
id oracle 

--si pas installé 
yum -y install oracle-database-preinstall-19c

--on verifie si le nombre de package a augmenté
rpm -qa | wc -l

--pour voir si oracle est isnstallé
id oracle 

--connection à oracle en changeant le password
passwd oracle 

sed -i 's/=enforcing/=permissive/g' /etc/selinux/config
setenforce 0
getenforce

--creation du repertoir pour etre dans les norme OFA
mkdir -p /u01/app/oracle/product/19.3.0/db1 /oradata /fra

chown -R oracle:oinstall /u01 /oradata /fra
chmod -R 775 /u01 /oradata /fra


systemctl disable --now firewalld

--Il faut copier par sftp sur /home/oracle le linux db home
--se connecter sur le compte oracle


--Finishing the Install

gedit  .bashrc

export ORACLE_BASE="/u01/app/oracle"
export ORACLE_HOME="$ORACLE_BASE/product/19.3.0/db1"
export PATH="$ORACLE_HOME/bin:$PATH"

--on enregistre les modifs
. .bashrc	

echo $ORACLE_HOME


cd $ORACLE_HOME


unzip -q ~/LINUX.X64_193000_db_home.zip
./runInstaller

export CV_ASSURME_DISTID=OEL7.6
./runInstaller


--creation de la base de donner avec le compte SYS

--Post-install Steps /home/oracle/
su -
yum -y install  rlwrap

chown -R :oinstall /tmp
logout 

gedit  .bashrc


--On ajoute ça à l'existant
if !  [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

alias sqlplus="rlwrap sqlplus"
alias lsnrctl="rlwrap lsnrctl"

--on enregistre les modifs
. .bashrc	

df -h

su -
mount -t tmpfs shmfs -o size=4096m /dev/shm

df -h

echo "tmpfs /dev/shm tmpfs size=4g 0 0" >> /etc/fstab



--Creating a Database
df -h

--lancement du client pour creation base
dbca
--creation de la global database name
--file location 
--initialisation parameters
--FRA : Fast recovery area
--creation sys
--undo tablespace
--dispachers
--memory target
--remote_login_passwordfile: Exclusive
--server parameter file name

tail -3 /etc/oratab


--The Listener

lsnrctl
--dans le cas ou message erreur
unalias lsnrctl

--voir le status du listener
lsnrctl> status
lsnrctl> service

--Local Database Connection
sqlplus / as sysdba

--si erreur alors on ajoute le SID
gedit  .bashrc

--Ajouter oracle sid
export ORACLE_SID="testdb"

. .bashrc


--la connexion devrait fonctionner 
sqlplus / as sysdba

SQL> startup

--Remote Connection - Easy Connect
su -

sqlplus / as sysdba
--si commande sqlplus not found

find  /u01 -name sqlplus 

export ORACLE_HOME="/u01/app/oracle/product/19.3.0/db1"
export ORACLE_SID="testdb"

$ORACLE_HOME/bin/sqlplus / as sysdba

--si invalid password

$ORACLE_HOME/bin/sqlplus sys/testdb@centos7/testdb as sysdba
show user

--Remote Connection - Dedicated Server
sqlplus / as sysdba

SQL> host lsnrctl start
SQL> startup
SQL> host lsnrctl status
SQL> host netmgr
 --Il faut ajouter le service dedié ded

SQL> conn sys/testdb@ded as sysdba


--Remote Connection - Shared Server
lsnrctl
service
netmgr
sqlplus sys/testdb@ss as sysdba
--verifier l'etat du service : established
SQL> host lsnrctl service


--Database vs INSTANCES
--Disk : Database
--RAM and CPU : Instance
--Networking
--relationship one to one
--database = disk(PERMANENT)
--instance = cpu + ram(TEMPORARY)

ls /oradata
sqlplus / as SYSDBA
select count(*) from dict;
startup

--Viewing the instance componement
ls /oradata
select count(*) from dict;
SQL> ! ls /oradata
instance = memory structures (RAM) + background processes (CPU)
SQL> ! ipcs -a
SQL> ! ps -aef | grep testdb | less
SQL> Shutdown IMMEDIATE
SQL> ! ipcs -a
SQL> ! ps -aef | grep testdb | less

--The Server Parameter File
SQL> Show parameters
SQL> select count(*) from v$parameter;
SQL> Show parameters db_create_f

--it is a binary file
find $ORACLE_HOME -name *spfile*

sqlplus / as SYSDBA
SQL> create pfile='/tmp/pfile.txt' from spfile;

--Now you can read the spfile easier
SQL> ! less -N /tmp/pfile.txt

--Pour avoir le nombre de ligne
SQL> ! wc -l /tmp/pfile.txt
SQL> select count(*) from v$parameter;
--On va supprimer le spfile
SQL> ! rm -rvf $ORACLE_HOME/dbs/spfiletestdb.ora

--Impossible de relancer une instance sans le spfile
SQL> startup force

SQL> create spfile from pfile='/tmp/pfile.txt';
SQL> ! ls $ORACLE_HOME/dbs/spfiletestdb.ora
--Dans ce cas l'instance se lance bien
SQL> startup 
SQL> ! du -h $ORACLE_HOME/dbs/spfiletestdb.ora
--The server parameter file is required to start your Database Insrtance

--The Alert log

SQL> ! find $ORACLE_HOME -name *alert_testdb.log*
--pour lire le fichier log
SQL> ! less <chemin fichier log>
--Pour avoir la taille du fichier
SQL> ! du -h <chemin fichier log>
--The alert log is a chronological diary of important database event
--it is an extremely useful troubleshooting tool

--Data files
These files contains your business data

SQL> select file_name, tablespace_name from dba_data_files;
SQL> col tablespace_name format a15
SQL> col file_name format a53
SQL> create table emps tablespace USERS AS SELECT username from dba_users;
SQL> SELECT count(*) from emps;

--we will rename datafile
cd <path to datafile>
ls
mv -v <name.dbf> <name>

sqlplus / as SYSDBA
SQL>alter system flush buffer_cache;
--Le select ressort en erreur
SQL>select * from emps;
--Le insert ressort en erreur egalement
SQL> insert into emps values('TEST');

-- Il faudra renommer le fichier comme à l'origine pour avoir accès au fichier

--The control file
--System checkpoint infrmation
--RMAN information 
--physical database structure
SQL> show parameter control_files
--on supprime le controle file pour faire le test
SQL> ! rm -rfv /fra/.....ctl
SQL> startup force
--Pour visualiser les log pour conprendre le probleme
SQL> ! tail -15 .....trace/alert_log_....log
--On va copier le controle file
SQL> ! cp -v /oradata/...xxxxx.ctl   /fra/....xxxxx.ctl 

SQL>  alter database mount;

SQL>  alter database open;
--Multiplex the control file to avoid disater
--ALL copies  of the control file are required to MOUNT the database

--Redo logs
--critical system and critical business
--Instance recovery after a system crash
--Media recovery after a drive failure
--Standby database processing
--Replication with Streams or Golden gate
--Historical transaction inspection using the LogMiner
--ACID test
--Durabilité :every commited change is immediately logged into the online logs
--When database server shuts down 
--the online redo log autmatcally recreate the commited change
--This is called Instance Recovery

--Demo: Redo Logs

SQL> select g.group#, g.status, f.member
     from v$log g, v$logfile f
     where g.group# = f.group#;

SQL> col status format a9
SQL> col member format a55

--Check size
SQL> ! du -h /oradata/..../fichier.log

--Pour faire le sitch vers un autre groupe de log
--Inactive, current, Active
SQL> alter system switch logfile;

--Redo Logs and Instance Recovery
























