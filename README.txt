README file for the Oracle Management Tool Suite.

Copyright (c) 2007, The Regents of the University of California. 
Produced at the Lawrence Livermore National Laboratory 
Written by Andy Rivenes, arivenes@llnl.gov. 
UCRL-CODE-234647. 
All rights reserved. 

This file is part of the Oracle Management Tool Suite. For details,
see https://github.com/AndyRivenes/orautil. 

The project web site is available at - https://github.com/AndyRivenes/orautil

For license information see - https://github.com/AndyRivenes/orautil/License.txt


*******************
* GETTING STARTED *
*******************

If you are using an OFA compliant directory structure then simply copy
the tool suite to the $ORACLE_BASE/local directory. Each utility either
has a README file or a README section at the beginning of the code.
 

****************
* INSTALLATION *
****************

Each utility will have either a README file or a README section at the
beginning of the code. At a minimum there will be an ORACLE_BASE parameter
that should be set (the default is /u01/app/oracle), and possibly a
config file that will need to be modified.


*******************
* UTILITY DETAILS *
*******************

Oracle environment control is maintained in metadata files located in the 
/var/opt/oracle or /etc directory. The oraInst.loc file is used by the Oracle 
Universal Installer to maintain the inventory directory location and installation 
group name. The oratab file is used to maintain the database SIDs defined, their 
corresponding ORACLE_HOME directory and a Y or N flag to indicate whether the 
database should be started on boot. The following will describe these files in 
detail and the extensions made to them. 

oratab File

The oratab file maintains information about the databases currently installed. 
It is created during installation by the root.sh script and updated by the 
Database Configuration Assistant (DBCA)  when creating new databases. The 
format of an entry is:

$ORACLE_SID:$ORACLE_HOME:<N|Y>

where $ORACLE_SID is the database system identifier, $ORACLE_HOME is the 
Oracle Server software directory for the database, and the third field is 
used by the "dbstart" utility with a "Y" indicating that the database should 
be started at system boot and a "N" indicating that it shouldn't. A colon 
terminates a field and comment lines are ignored by the Oracle utilities.

oratab Extensions

The oratab file has been extended through the use of comments that allow it 
to be used to maintain additional information for other Oracle Server utilities 
as well. By using additional comments, Oracle provides commented information in 
this file as well, the integrity of the file is maintained and no Oracle supplied 
utilities that use this file are affected. 

The standard Oracle supplied utilities provide no ability to handle the additional 
server utilities, their locations, and additional options that must be known in 
order to start them. A good example is the SQL*Net listener. A single SQL*Net 
listener can support multiple Oracle databases, and each of these databases can 
have a unique ORACLE_HOME. In addition, there can be multiple listeners defined 
for a given ORACLE_HOME, or again for multiple ORACLE_HOMEs.

In order to support these additional Oracle Server utilities the oratab file 
is modified with additional comment lines to define the Oracle utilities available, 
their locations and any options. The following lists the current oratab format 
recommendations, and these do not interfere with Oracle supplied tools and scripts 
and do not violate Oracle's syntax for this file:

<SID>:<ORACLE_HOME>:<Y|N> <== Oracle standard format 
#<utility>:<ORACLE_HOME>:<option(s)> 
#APPLMGR:<applid>:<appl node>:<alias> 

The following lists the different options currently supported:

   <SID> - the Oracle database system identifier   
   <ORACLE_HOME> - the Oracle software directory
   <Y|N> - Y signifies that the database should be started during a
           system reboot, N signifies that it shouldn't (Oracle
           default).
           Custom environment setup utilites set ORACLE_SID if a Y
           and TWO_TASK if an N. 

   <utility> is:

           NETV1 - SQL*Net Version 1 
           SNET  - SQL*Net Version 2, Net8, Net8i, Net9, Oracle Networking (10g)
           NAMES - Oracle Names
           AGENT - Oracle Intelligent Agent
           OBACK - Obackup (EBU prior to 2.2)
           EBU   - EBU 2.2
           OID   - Oracle Internet Directory
           OEM   - OEM Managment Server
           OWS3  - Oracle Web Application Server 3
           OC4J  - Oracle Containers For J2EE (standalone)
           AS9   - Oracle9i Application Server
           AS10  - Oracle 10g Application Server
           GRID  - Oracle Grid Control (10g AS based)
           OCA   - Oracle Certificate Authority

   <option(s)> is one or more options, separated by a ":".
     Based on the utility keyword, the following options
     are supported:

       SNET - listener alias (for multiple listener 
              support), defaults to LISTENER if not supplied.
       OID  - server name, oidlapd|oidrepld, instance 
              number, and configset number in that order
              (instance number and configset number are optional,
              and default to 1 and 0 respectively).
       OWS3, AS9, AS10, GRID - 
              Infrastructure database network alias.
       OEM, AGENT -
              Database SID for 10g. 
              Note: AGENT should not be used with 10g dbconsole.

   APPLMGR is:
     <applid> is the applmgr UNIX id
     <appl node> is the applmgr node name
     <alias> is the Oracle Applications system alias
       (e.g. OAPRD, used to identify multiple systems
        or if server partitioning is used on a single
        node), <alias> is optional.

For server partitioned environments two entries are required. One for the database, 
presumably with a flag of "Y", and one for the Oracle Applications product files 
with a flag of "N" (an "N" flag causes orasetup to set the TWO_TASK environment 
variable rather than the ORACLE_SID environment variable). 

   STANDBY is:
     This flag is only used on the standby database server.

     <sid> the SID of the Oracle standby database.
     <option> one of the following:

       NOSTART - Do not start the Standby instance - only
                 valid with the start all option.
       MOUNT -   Mount the standby database
       MANAGED - Mount and place standby in managed 
                 recovery mode - requires the script ...
       READ -    Mount and open the standby in read only
                 mode

NOTE: Utility keywords and <alias>|<options> must be upper case.
oratab Examples
The following are examples of actual oratab files used in supported systems:
Example 1 - Oracle 10g database with standalone OC4J
#
UIDPRD:/oracle/product/10.2.0/db_1:Y
#OC4J:/oracle/product/10.1.0/oc4j_1:UIDPRD
#SNET:/oracle/product/10.2.0/db_1:LISTENER
#OEM:/oracle/product/10.2.0/db_1:UIDPRD

Example 2 - Grid Control system
#
*:/u01/app/oracle/product/10.2em/agent10g:N
emrep:/u01/app/oracle/product/10.2em/db10g:Y
#GRID:/u01/app/oracle/product/10.2em/oms10g:emrep
#SNET:/u01/app/oracle/product/10.2em/db10g:LISTENER

Example 3 - Standard Database system
#
SMSGPRD:/oracle/product/9.2.0:Y
NAS:/oracle/product/9.2.0:Y
#SNET:/oracle/product/9.2.0:LISTENER
#AGENT:/oracle/product/9.2.0

Example 4 - Standby Database System
#
SMSGPRD:/oracle/product/9.2.0:N
#STANDBY:SMSGPRD:MANAGED
#SNET:/oracle/product/9.2.0:LISTENER
#AGENT:/oracle/product/9.2.0

Example 5 - 10g AS System
Application Server:
#
#AS10:/u01/app/oracle/product/9.0.4:PASDB

Infrastructure Database:
#
PASDB:/u01/app/oracle/product/9.2.0:Y
#SNET:/u01/app/oracle/product/9.0.4:listener
#AS10:/u01/app/oracle/product/9.0.4:PASDB
#AGENT:/u01/app/oracle/product/9.2.0

Oracle Supplied Environment Setup

Oracle supplies the utilities coraenv/oraenv and dbhome to help customers 
with environment setup. These utilities use the "oratab" file to obtain the 
correct ORACLE_HOME for the database SID being accessed. Unfortunately these 
utilities have limited functionality. Not all environment variables are set 
and no support is available for other utilities (e.g. SQL*Net listener(s), 
Intelligent Agent, etc.).

Oracle Supplied Database Startup and Shutdown

Oracle supplies the scripts dbstart and dbshut to automate the startup and 
shutdown of all databases based on their "oratab" entry. These scripts can 
be run by hand or when the operating system is started or stopped. Unfortunately 
there is no mechanism for dealing with the SQL*Net listener, Intelligent Agents 
or Oracle Applications concurrent manager processes. 

Custom Environment Control Utilities

All custom environment utilities are located in the directory 
$ORACLE_BASE/local/script.  This directory is usually placed in the PATH to allow 
each utility to be run without having to be prefaced with the full directory path. 
The following describes each of the utilities.

corasetup

corasetup is a c-shell based UNIX environment setup utility and is an enhanced 
replacement for the coraenv utility. Using the setting of the ORACLE_SID environment 
variable as input, the utility will setup the UNIX environment based on the SID 
information defined in the oratab file. Typically, additional corasetup_<SID> scripts 
will be created to set the ORACLE_SID environment variable for each of the databases 
defined and then invoke the corasetup script. Since the script is meant to change the 
existing shells environment, the "source" command must be used to invoke corasetup.

Example:

$ source corasetup
or
$ source corasetup_orcl

orasetup

orasetup is a korn/bash shell based UNIX environment setup utility and is an enhanced 
replacement for the oraenv utility. The orasetup utility requires a corresponding <SID> 
or <utility> parameter as defined in the oratab file. The utility will then set the UNIX 
environment variables accordingly. If no parameter is supplied and an entry starting with 
an "*" exists, then that entries ORACLE_HOME will be used. This is useful when no database 
has been created, but there exists an ORACLE_HOME installation. The utility also accepts 
a "version" and a "help" or "?" parameter.

Examples:

$ . orasetup version
 
+-+-+  orasetup, Ver 6.6, 05/04/2005
 
or

$ . orasetup orcl

dbcontrol

dbcontrol is a korn/bash shell based UNIX script that is an enhanced replacement for 
dbstart/dbshut utilities. dbcontrol can be used to start, stop or check the status of  
databases and utilities defined in the oratab file, and can be called during system 
reboot to startup or shutdown all database services. When the "start all" or "stop all" 
options are used then a log of all actions is created in the $ORACLE_BASE/local/log 
directory. An interactive and command line mode is supported and help options provide 
detailed option information.

Example:

$ dbcontrol ?

+-+-+  dbcontrol, Ver 11.3, 05/02/2006
 
 
Usage: dbcontrol [ start                [ all | sid ]
                   stop                 [ all | sid ] [ abort ]
                   mount                [ sid ]
                   standby              [[ mount | managed | read | stop ] sid ] | [ check ]
                   agent|names|oid      [ start | stop | check ]
                   listen|oem           [ start | stop | check ] | <alias>
                   conc                 [ start | stop [ wait ] | check ] | <alias>
                   status 
                   ? 
                   help ]

ascontrol

ascontrol is a korn/bash shell based UNIX script that supports management of Oracle 
Application server process and stand-alone OC4J. Like dbcontrol, ascontrol can be used 
to start, stop and check the status of Oracle Application Server Release 1 through 3 
processes and stand-alone OC4J. Its operation and setup is similar to dbcontrol, but 
ascontrol is dependent on orasetup so orasetup must also be installed.

Example:

$ ascontrol ?
 
+-+-+  ascontrol, Ver 2.5, 04/28/2006
 
Usage: ascontrol [ oc4j|as10|grid ] 
                     [ start|stop|status [ all ]]
                     [ startproc [ name ]] 
                   status 
                   startall 
                   stopall 
                   ? 
                   help ]

System Reboot

During a system reboot, or during any system startup or shutdown, the Oracle database 
services should be started or stopped automatically. The Oracle installation guides 
document a script called "dbora" that can be called by the OS startup and shutdown 
routines to accomplish this. This script can be easily modified to call dbcontrol to 
startup and shutdown all processes defined in the oratab file.

dbora

dbora is a bourne shell script that can be called by the init process at startup and 
shutdown. The script has been modified so that it calls dbcontrol with "START ALL" or 
"STOP ALL" parameters depending on whether it's being called during a startup or 
shutdown of the machine. The script can also call ascontrol to start or stop Application 
Server proceses.

The file should be located in the /etc/init.d directory during database installation. 
Full installation instructions are included in the comments at the beginning of the 
script.

Startup And Shutdown

During system startup and shutdown, files in the rc?.d directories are run where ? is 
the init state. Files are named with the convention [SK]nn<init.d filename>, where S 
means start this job, K means kill this job, and nn is the relative sequence number 
for killing or starting the job. 

Solaris

For Oracle system startup, a link to the dbora script in /etc/init.d is made with the 
symbolic name of S99dbora in the /etc/rc3.d directory. 
For Oracle system shutdown a link to the dbora script in /etc/init.d is made with the 
symbolic name K10dbora in the /etc/rc0.d directory.
It is important that during system startup the Oracle system is one of the last things 
brought up. Hence the Snn<init.d filename> link should have one of the highest nn numbers, 
if not the highest. During system shutdown, the Oracle system should be one of the first 
things shutdown. Hence the Knn<init.d filename> link should be one of the lowest nn 
numbers, if not the lowest.

Linux

On Linux systems the "chkconfig" process can be used. The dbora file contains a 
chkconfig line that directs the chkconfig process to create the appropriate rc?.d 
entries automatically.


*******************
* BKCTRL          *
*******************

BKCTRL is a korn shell script to run ORACLE database backups. It is made up of several
functions and currently supports the following backup types:

	external - defaults to Legato "save" command
	tar -      uses tar to back up files
        obackup -  support for versions prior to 2.2.
        ebu -      support for version 2.2.
        rman -     versions 8 and 8i, uses the files rman_TAPE.ksh and
                   rman_DISK.ksh for the actual RMAN "run" commands.
        rman9i -   version 9i, uses the files rman9i_TAPE.ksh and
                   rman9i_DISK.ksh for the actual RMAN "run" commands. 
        rman10g -  support for 10g, uses the files rman10g_TAPE.ksh,
                   rman10g_DISK.ksh, 10gFLASH_DISK.ksh and 10gFLASH_TAPE.ksh
                   for the actual RMAN "run" commands.
        AS10 -     support for Oracle Application Server 10g Release 1 using
                   the 10g AS backup and recovery tool (e.g. bkp_restore.pl).

Online and offline backups are supported as well as archivelog backups. For 
Obackup/EBU and RMAN backups are supported to disk as well as Legato or 
Veritas managed media. 

RMAN 9i and 10g support has been added, along with FLASH recovery support and
support for level 0 and level 1 incremental backups.

10g Application Server support has been added for offline and online backups
using 10g AS guidelines and the 10g AS backup and recovery tool.

Log files are created for use during restores and for review. Emails are sent
when errors occur (whether run interactively or batch), and there is now a
feature to log a summary of the backup to a centralized schema.  This 
facilitates managing many database backups, and tracking completion status
and times to backup. It also allows the ability to implement automated
recovery for 10g AS installations utilizing DataGuard for infrastructure
database protection.


Example:

$ bkctrl.ksh

Usage:  bkctrl.ksh  
             ORACLE_SID [ offline | online ] [ all | pre | post ] [ full | incr0 | incr1 ] 
                          tablespace {tablespace name} 
                          long {tablespace name} 
                          archive  [ all | force | pre | post ] [ keep | delete ] 
                          register 
                          resync 
                          clean 
             AS10 [ offline | online ] 
                    clean 


The parameters are detailed below:

    1. SID (i.e. ORCL)

       online/offline
         - all/pre/post
         - full/incr0/incr1 (incrementals for RMAN only)
       archive
         - all/force/pre/post
         - keep/delete (i.e. archive log files)
       tablespace/long
         - tablespace name(s) {all CAPS, comma delimited, no spaces}
       register
         Used for EBU and to initially register a database in an RMAN catalog.
       resync
         Used to synchronize a database and an RMAN catalog.
       clean
         Used to manually delete disk backup files.

    2. AS10

       online/offline
       clean
         Used to manually delete disk backup files.


*******************
* SPACEMON        *
*******************

The SPACEMON utility monitors Oracle database segment space history.
This utility is made up of a stored procedure that snapshots current
database segments and their associated storage information and is
meant to be run on a periodic basis (e.g. weekly) as part of an
interval monitoring strategy for managing Oracle databases.

There are additional, optional components to this utility:

  SPACERPT - Space Reporting

  There is a space report utility that uses current database 
  information and the SPACEMON interval monitoring data to create
  a report on the current status of database segment space usage.

  SPACEFIX - Space Growth

  The SPACEFIX component can be used to automatically 
  resize the NEXT_EXTENTs of objects that have extended over the
  last three collection periods, or if the object has extended 
  five times in a 12 month period and the NEXT_EXTENT size has
  remained the same.

  This utility is fully compatible with Locally Managed Tablespaces
  and has been tested through Oracle Server Version 9.0.  Currently
  the following segment types are tracked: TABLE, INDEX, TABLE 
  PARTITION, INDEX PARTITION, CLUSTER, LOB.

  SPACESTATS - Statistic Generation

  The SPACESTATS component can be used to automatically 
  re-generate statistics for tables or table partitions that have
  extended during the last collection period.

  This utility is fully compatible with Locally Managed Tablespaces
  and has been tested through Oracle Server Version 10g.  Currently
  the following segment types are tracked: TABLE, TABLE PARTITION.

  SPACEIDX - Index Rebuilds

  This utility will identify indexes that are good candidates to be rebuilt.
  Indexes that have extended in the last collection period will be ANALYZED
  and a REBUILD statement will be created if the index utilization is less
  than a fixed percentage (currently 60 percent).
  Ideally this utility should be run after each SPACEMON collection.
  If set, the utility automatically rebuild the index(es) as part of the
  execution.  Otherwise, the rebuild syntax will be output as part of the
  SPACEIDX report.

  As always, all changes are audited to the spc_chng_audit table.  In the
  case of SPACEIDX, the initial extent size is set to 0.  This identifies
  and index rebuild as opposed to a next extent resize.

  SPACEEXT - Segment Extension Warning

  This utility will provide an email warning if there are any segments that 
  can't extend.  The purpose is to provide an additional warning in between
  regular SPACEMON runs. 

  SPCGATHER - Analyze SPACEMON Objects

  This utility will analyze SPACEMON objects.  We recommend scheduling this
  to run once a month.

  SPACEMON

  For UNIX environments a korn shell script, spacemon.ksh, has been 
  written that can be scheduled and will run all three components and
  email the results to a specified email address.

Example:

  SPACEMON is usually run through cron. The following entries provide a
  starting guide:

    05 20 * * 5 /u01/app/oracle/local/spacemon/spacemon.ksh \
    <dbname> > /dev/null 2>&1
    20 20 * * *  /u01/app/oracle/local/spacemon/spaceext.ksh \
    <dbname> > /dev/null 2>&1
    30 20 1-12 * * /u01/app/oracle/local/spacemon/spcmaint.ksh \
    <dbname> > /dev/null 2>&1

  Note: The command should be on one line and the "\" removed.
  For machines running more than one database an optional
  database name can be supplied to spacemon.ksh script as a parameter.
  Otherwise it can be removed.  The file makecron.txt in the install
  directory shows an example.


*******************
* SYSMON          *
*******************

Sysmon was originally developed as a means to track database file 
I/O over time.  It was written over the summer of 1995 and 
presented at the Spring 1995 OAUG conference in Washington D.C.

It has evolved into a long term interval monitoring tool for Oracle
databases.

The main premise is to use the statistics available from the Oracle
database to provide information on the rate of work being done by the
database.  The basic format at the system level of this is 
"elapsed time = service time + wait time".  OS statistics are optionally
tracked to provide a correlation.

The primary format of the "daily" summary is to provide interval 
information on CPU, memory, and I/O rates (both file and redo).
Some additional statisitcal information is also provided about user
connections and key architecture components of the database.

The information tracked makes it possible to do both workload
characterization and capacity planning.

Example:

  SYSMON is usually run through cron. The following entries provide a
  starting guide:

    10 * * * * /u01/app/oracle/local/sysmon/moncolst.ksh \
      <dbname> > /dev/null 2>&1
    05 20 * * 1-5 /u01/app/oracle/local/sysmon/monprint.ksh \
      <dbname> > /dev/null 2>&1
    15 22 1-12 * * /u01/app/oracle/local/sysmon/mongather.ksh \
      <dbname> > /dev/null 2>&1

  Note: for machines running more than one database an optional
  database name can be supplied to moncolst.ksh, monprint.ksh,
  and mongather.ksh as a parameter.

