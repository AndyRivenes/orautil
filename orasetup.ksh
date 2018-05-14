#!/bin/ksh
##!/bin/bash
#
# Copyright (c) 2007, The Regents of the University of California. 
# Produced at the Lawrence Livermore National Laboratory 
# Written by Andy Rivenes, arivenes@llnl.gov. 
# UCRL-CODE-234647. 
# All rights reserved.
#
# This file is part of the Oracle Management Tool Suite. For details,
# see https://github.com/AndyRivenes/orautil.
#
# The project web site is available at - https://github.com/AndyRivenes/orautil
#
# For license information see - https://github.com/AndyRivenes/orautil/License.txt
#
#
# Date:          09/17/2007
#
# Description:   Oracle environment setup shell script.  This script is a direct
#                replacement for the server scripts oraenv/dbhome with significant
#                enhancements.  It is dependent on an OFA compliant environment
#                and uses the file "oratab" to set a correct Oracle server 
#                environment. "orasetup" also bases server version specific
#                environment requirements on the ORACLE_HOME path syntax.  This
#                assumes the path is named with the format -  
#                $ORACLE_BASE/product/<version> (e.g. /u01/app/oracle/product/8.1.6).
#
#                "orasetup" supports proper environment setup for all versions of
#                Oracle from 7 through 11g, including 32-bit and 64-bit versions.
#
#                If the database is set to start (e.g. Y or W flag in the third
#                position) then the ORACLE_SID is set, otherwise TWO_TASK is set.
#                This is especially useful for client tool environments and Oracle
#                Applications server partitioned environments.
#
#                Based on the "oratab" file the ORACLE_HOME and PATH environment
#                variables are also set.  LD_LIBRARY_PATH/SHLIB_PATH is set 
#                based on the ORACLE_HOME value and any platform dependencies
#                (e.g. the GBL_LDPATH optional parameter).
#
#                The following additional parameters are set based on the version of
#                the ORACLE_HOME used (this is determined based on an OFA expected
#                naming convention - example /u01/app/oracle/7.3.4):
#                  
#                NLS_LANG (optional), ORA_NLS, ORA_NLS32, ORA_NLS33, ORACLE_TERM,
#                and EPC_DISABLED.
#
#                Additionally there is support for Oracle Enterprise Backup Utility
#                and RMAN.  If using Legato, NSR variables can also be set, but are
#                dependent on the bkctrl config file existing - see the separate
#                Oracle Backup Utility Guidelines document for further information.
#
#                Note: Server partitioned environments are supported through the
#                "N" oratab database flag.  Since TWO_TASK is set for databases with
#                the "N" flag set, another alias can be set for the server partitioned
#                ORACLE_HOME environment.  It is recommended that the SQL*Net alias
#                for that environment be used. As of orasetup version 2.1 this behavior
#                can be overridden so that the ORACLE_SID variable remains set.
#
#                orasetup supports Oracle Application Server environments as well as
#                standalone OC4J. See the "External Requirements" section for the proper
#                labels to be used in the oratab file.
#
#                orasetup is now 11i aware, however this is meant only to ensure that
#                the database environment is set correctly.  This is not meant to be
#                a substitute for running the Oracle Applications setup scripts (e.g.
#                APPSORA.env).  "orasetup" looks for a SID.env file in ORACLE_HOME and
#                if it exists it runs it.  This is consistent with how Rapid Install
#                configures the environment file setup for the database tier.
#
#                orasetup will check for Linux 64-bit mode when running the AS10 or
#                GRID options. Since 10g AS only supports 32-bit mode a return code of
#                3 if in 64-bit mode.
#
#                orasetup supports the ability to call an external file with additional
#                environment setup commands. This file is expected to be of the format 
#                <SID>.env is based on the parameter passed to orasetup. It is expected
#                to be in the directory defined in the DEPVAR function by the GBL_USERENV
#                variable. If this parameter is set and the file is readable then
#                orasetup will run it in the current environment.
#
#                Return codes:
#                  0 - Normal
#                  1 - Error condition
#                  2 - TWO_TASK has been set
#                  3 - Warning, 32-bit mode required
#
# External 
# Requirements:  "oratab" configuration.  See installation section for format details.
#                Remains OFA compliant.
#
#                Expects the UNIX commands: sed, awk, uname, grep to be in the PATH.
#                Will run in either the korn shell or bash. If running in bash then
#                uncomment the bash interpreter call and move up to the first line
#                (e.g. it should look like: "#!/bin/bash line", and comment out or remove
#                the "#!/bin/ksh" line).
#
#                This script uses the file "oratab" in order to determine the database
#                and its location.  It will also support additional keywords to support 
#                SQL*NET listeners, NameServers, and agents.  This is helpful for 
#                environments running multiple versions of the Oracle Server software
#                since there is no mechanism to determine the versions that those
#                utilities are running.
#
#                The following is the supported "oratab" format.  It uses comments in the
#                following manner to support additional server utilities (Note: This
#                remains Oracle compliant):
#
#                  <db sid>:<ORACLE_HOME>:<Y|N|W>  <== Oracle standard format (see comments above)
#                  #<utility>:<ORACLE_HOME>:<option(s)>
#
#                  Where utility is:
#                    NETV1 - SQL*Net V1
#                    SNET  - SQL*Net V2/Net8
#                            option: Listener name
#                            multiple entries are supported
#                    NAMES - Oracle Names
#                    AGENT - Oracle Intelligent Agent
#                    OBACK - Obackup (EBU prior to 2.2)
#                    EBU   - EBU 2.2
#                    OID   - Oracle Internet Directory
#                    OEM   - OEM Managment Server
#                            option: 10g database SID, supports 10g dbconsole
#                    OWS3  - Oracle Web Application Server 3
#                    OC4J  - Oracle Containers For J2EE (standalone)
#                    AS9   - Oracle9i Application Server
#                            option: Infrastructure database alias
#                    AS10  - Oracle 10g Application Server
#                            option: Infrastructure database alias
#                    GC10  - Grid Control, see AS10
#                    WL11  - Oracle 11g Fusion (Weblogic)
#                            option: Server name
#                    HTTP  - Oracle HTTP Server
#                    OCA   - Oracle Certificate Authority
#                    CRS   - Oracle Cluster Ready Services
#                    GRID  - 11gR2 clusterware
#
#                  NOTE: Case is enforced for utility keywords.
#
# Installation:  1) Recommend locating orasetup in the $ORACLE_BASE/local/script directory.
#                2) Recommend adding $ORACLE_BASE/local/script to the oracle account's PATH.
#                3) Verify that all databases are set correctly in the oratab file.
#                4) Modify the DEPVAR function to set environment specific variables. The
#                   only required modification is to the ORACLE_BASE setting.
#                   NOTE: If using Application Server services then the LVAR setting for
#                         JAVA_HOME must be set.
#                5) If using the bash shell then uncomment the bash interpreter call
#                   at the top of this file and move up to the first line
#                   (e.g. it should look like: "#!/bin/bash line", and comment out or
#                   remove the "#!/bin/ksh" line).
#                6) For detailed ssh equivalence setup see 
#                   http://appsdba.com/techinfo/equivalence.htm
#
# Modifications:
# 1.0,  09/17/2007, A. Rivenes, Initial open source release.
# 1.1,  06/06/2008, A. Rivenes, Created an SSH equivalence option so it wouldn't be
#                               run every time orasetup was invoked.
# 1.2,  06/26/2008, A. Rivenes, Fixed TWO_TASK check to handle "*" for third field.
# 1.3,  08/19/2008, A. Rivenes, Added the ability to run a central (i.e. orautil.cfg) or
#                               a script specific (i.e. orasetup.cfg) configuration file.
# 1.5,  10/17/2008, A. Rivenes, Added a keyword bypass in case a keyword is being used in
#                               the oratab file as a valid label.
# 1.6,  11/03/2008, A. Rivenes, Added 11g support for ORACLE_HOME naming.
# 1.7,  12/04/2008, A. Rivenes, Added formatting enhancements, support for multiple AS
#                               environments.
# 1.7a, 01/09/2008, A. Rivenes, Fixed an error parsing oratab labels.
# 1.8,  08/12/2009, A. Rivenes, Added a "menu" function to list the contents of the oratab
#                               file.
# 1.8a, 08/14/2009, A. Rivenes, Updated the list of utilities in the OMENU function (forgot
#                               OBACK and EBU), and updated the help with more complete
#                               syntax and explanations.
# 1.8b, 08/27/2009, A. Rivenes, Added check for oratab existence.
# 1.8c, 08/28/2009, A. Rivenes, Fixed oratab existence check from -d to -r.
# 1.9,  09/01/2009, A. Rivenes, Added support for 11g Fusion app server with label: WL11,
#                               added check for directory existence before setting, cleaned
#                               up left over variables from OMENU function.
# 2.0,  09/04/2009, A. Rivenes, Made changes to parse ORACLE_HOME once for version and
#                               set major and minor version variables.
# 2.1,  01/30/2009, A. Rivenes, Added option to ignore startup flage (i.e. always sets
#                               ORACLE_SID). Changed original GRID label to GC10 since
#                               11gR2 clusterware now uses the "grid" label.
# 2.2,  06/05/2011, A. Rivenes, Added support for 11.2 ORACLE_UNQNAME. Fixed problem
#                               with grep'ing for strings, switched to egrep. This was
#                               fixed in dbcontrol and missed it here.
# 2.3,  02/10/2012, A. Rivenes, Problem with Oracle adding a comment after database entries.
#                               The awk was picking up the commnet with the flag. Added
#                               a "cut" to just get the first column returned.
#                               Changed the epc_disabled parameter to only be set for
#                               for versions through Oracle 9. The parameter is used
#                               to disable Oracle Trace for SQL*Net connections.
#                               Changed the GBL_USERENV variable.
#                               Added support for 11.2 ORACLE_UNQNAME.
# 2.3a, 02/21/2013, A. Rivenes, Fixed comment for 2.3 above and GBL_OFLAG usage in the DEPVAR
#                               function.
# 2.3b, 08/10/2017, A. Rivenes, Separated SQLPATH and ORACLE_PATH, renumbered LVARs
# 
#
# Script Notes:
#
#   1) Oracle uses a cat and pipe into its while loops in dbstart/dbshut, but this fails
#      in some shells because those shells spawn a sub-shell to execute the command and
#      so exported variables are not retained. orasetup instead uses input redirection to
#      get around this problem.
#
#
# Usage:  orasetup [ SID | <utility> [ alias ]
#                    unset | opatch | ssh
#                    help | ? | version| menu ]
#
#
#########################################################################################
#
# VERSION - Display utility version
#
#########################################################################################
function VERSION {
  echo " "
  echo "+-+-+  orasetup, Ver 2.3b, 08/10/2017"
  echo " "
  return 0
}
#########################################################################################
#
# DEPVAR - Set utility dependent variables
#
#   Global Variables (Korn shell does not support "inheritance" of local variable values,
#     so these variables cannot be "typeset"):
#
#     GBL_LDPATH
#     GBL_LDPATH64
#     GBL_LBIN
#     GBL_TR
#     GBL_OTERM
#     GBL_OSH
#     GBL_BKUPCFG
#     GBL_ORATAB
#     GBL_PORT
#     GBL_USERENV
#     GBL_MAJ_VER (set in SETHOME)
#     GBL_MIN_VER (set in SETHOME)
#
#########################################################################################
function DEPVAR {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  typeset CFGDIR
  typeset CFGFILES
  typeset CFGFNAM
  #
  # Set port
  #
  GBL_PORT=`uname`
  #
  # Oracle Environment specific variables
  #
  if [ -z "$ORACLE_BASE" ]; then
    ORACLE_BASE="/u01/app/oracle"
    export ORACLE_BASE
  fi
  #
  # Set configuration directory and files to search
  #
  CFGDIR="$ORACLE_BASE/local/script"
  CFGFILES="orasetup.cfg orautil.cfg"
  #
  GBL_OTERM=vt220
  #
  # Enable osh check and run if needed
  #
  GBL_OSH=1
  #
  # Backup config files (e.g. bkctrl) - if present will set NSR variables
  # for EBU/RMAN
  #
  GBL_BKUPCFG=$ORACLE_BASE/local/bkup
  #
  # Define the directory to search for a user defined environment script
  #
  GBL_USERENV="$ORACLE_BASE/local/script"
  #
  # Define the directory to search for a ssh equivalence script
  #
  GBL_SSH="$HOME/.ssh"
  #
  # Define whether orasetup will set TWO_TASK for entries with an :N flag
  # If set to 1 orasetup will set TWO_TASK for entries with an :N flag;
  # If set to 0 orasetup will always set ORACLE_SID
  #
  GBL_OFLAG=1
  #
  # Allow setting local environment variables, format LVAR[#] where # is a sequentially
  # increasing number. See below for an example:
  #
  # Windows only
  #LVAR1="SQLPATH=/home/oracle/sql"
  #
  # Linux only
  LVAR1="ORACLE_PATH=$ORACLE_BASE/local/sql"
  #LVAR2="LD_ASSUME_KERNEL=2.4.19"
  #LVAR2="TNS_ADMIN=$ORACLE_BASE/admin/snet/admin"
  #
  # NOTE: JAVA_HOME is required for Application Server products!
  #
  #LVAR2="JAVA_HOME=/usr"
  #LVAR2="NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1"
  #LVAR2="NLS_DATE_FORMAT=Mon DD YYYY HH24:MI:SS"
  #LVAR2="LDEMULATION=elf_i386"
  #LVAR2="OPATCH_PLATFORM_ID=23"
  #LVAR2="DISABLE_HUGETLBFS=1"
  # Set if more temp space is needed than /tmp
  #LVAR2="TMP=/u01/app/oracle/tmp"
  #LVAR3="TMPDIR=/u01/app/oracle/tmp"
  # Multihomed computer
  #LVAR2="ORACLE_HOSTNAME=somehost.us.example.com"
  #
  # NLS Notes:
  #   In Oracle8, NLS, If you do not use the default characterset (American_America.US7ASCII)   
  #   you must set NLS_LANG to language_territory.charset.  This is becuase 
  #   of bug 508042 which is fixed in 8.0.4.
  #
  #   As of 8.1.6 NLS_LANG must be set when creating a database with a character set
  #   other than US7ASCII.
  #
  #   When using RMAN it is recommended to have NLS_LANG and NLS_DATE_FORMAT set.
  #
  # Port specific UNIX environment settings
  # GBL_ORATAB   - Sets oratab location
  # GBL_LDPATH   - Used to append additional site libraries to the 
  #                LD_LIBRARY_PATH/SHLIB_PATH/LIBPATH - 32-bit
  # GBL_LDPATH64 - Used to append additional site libraries to the
  #                LD_LIBRARY_PATH/SHLIB_PATH/LIBPATH - 64-bit
  # GBL_LBIN     - Used to append additional site libraries to the PATH
  #
  case $GBL_PORT in
    "HP-UX" ) GBL_ORATAB="/etc/oratab"
              GBL_LDPATH="/usr/dt/lib:/usr/lib"
              GBL_LDPATH64="/usr/lib"
              GBL_TR="/bin/tr"
              GBL_LBIN="/usr/bin"
              ;;
      "AIX" ) GBL_ORATAB="/etc/oratab"
              GBL_LDPATH=""
              GBL_LDPATH64=""
              GBL_TR="/usr/bin/tr"
              GBL_LBIN="/usr/bin"
              ;;
    "SunOS" ) GBL_ORATAB="/var/opt/oracle/oratab"
              GBL_LDPATH="/usr/dt/lib:/usr/lib:/usr/openwin/lib"
              GBL_LDPATH64="/usr/lib"
              GBL_TR="/bin/tr"
              if [ -d "/usr/xpg4/bin" ]; then
                GBL_LBIN="/usr/xpg4/bin:/usr/bin"
              else
                GBL_LBIN="/usr/bin"
              fi
              ;;
    "Linux" ) GBL_ORATAB="/etc/oratab"
              GBL_LDPATH="/usr/dt/lib:/usr/lib:/usr/lib/X11"
              GBL_TR="/usr/bin/tr"
              GBL_LBIN=""
              #GBL_LBIN="/usr/openv/netbackup/bin"
              ;;
          * ) GBL_ORATAB="/etc/oratab"
              GBL_LDPATH=""
              GBL_LDPATH64=""
              GBL_TR="/bin/tr"
              GBL_LBIN=""
              ;;
  esac
  #
  # Run a site or script specific configuration file if it exists
  #
  if [ -n "${CFGDIR}" ]; then
    for CFGFNAM in ${CFGFILES}; do
      if [ -r "${CFGDIR}/${CFGFNAM}" ]; then
        . ${CFGDIR}/${CFGFNAM}
        if [ $? -ne 0 ]; then
          echo "Error running external configuration script: ${CFGDIR}/${CFGFNAM}"
          RC=1
        fi
        #
        break
      fi
    done
  fi
  #
  return $RC
}
#########################################################################################
#
# HELPMSG - Display help message
#
#########################################################################################
function HELPMSG {
  echo " "
  echo "Usage:  . orasetup { <SID> | <utility> [alias] "
  echo "                     unset | opatch | ssh "
  echo "                     help | ? | version| menu } "
  echo " "
  echo " "
  echo "Note: The command MUST be prefaced with a \".\". If it is not then"
  echo "      no permanent change can be made to the user's environment."
  echo " "
  return 0
}
#########################################################################################
#
# HELPFULL - Display help detail
#
#########################################################################################
function HELPFULL {
  echo "Options: "
  echo "         SID - Database SID based on first label in the oratab file "
  echo "         <utility> [ alias ] - recognized utility and optional alias "
  echo "           as defined by #<utility>: format in the oratab file "
  echo "         unset    - Unset all variables set by orasetup "
  echo "         opatch   - Add \$ORACLE_HOME/OPatch to the PATH "
  echo "         ssh      - Runs ssh.env in \$HOME/.ssh (default) to set "
  echo "           ssh equivalence "
  echo "         help | ? - Display this help message "
  echo "         version  - Display orasetup version "
  echo "         menu     - Display database and known utilities defined in "
  echo "           the oratab file "
  echo " "
  return 0
}
#########################################################################################
#
# OMENU - Display oratab file
#
#########################################################################################
function OMENU {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  typeset OLINE
  typeset OHOME
  typeset OSID
  #
  # Process oratab file
  #
  echo " "
  #
  if [ -r $GBL_ORATAB ]; then
    while read OLINE; do
      case $OLINE in
        \#*)
          # comment-line in oratab
          #
          OSID="`echo $OLINE | awk -F: '{print $1}' -`"
          #
          case $OSID in
            "#NETV1"|"#SNET"|"#NAMES"|"#AGENT"|"#OID"|"#OEM"|"#OWS3"|"#OC4J"|"#AS9"|"#AS10"|"#WL11"|"#OCA"|"#GC10"|"#HTTP"|"#CRS"|"#GRID"|"#EBU"|"#OBACK")
              OHOME="`echo $OLINE | awk -F: '{print $2}' -`"
              #
              printf "Alias: %-13s %18s\n" ${OSID} ${OHOME}
              ;;
          esac
          ;;
        \**)
          # asterisk-line in oratab - signifies default ORACLE_HOME
          OHOME="`echo $OLINE | awk -F: '{print $2}' -`"
          #
          printf "Alias: %-13s %18s\n" '*' ${OHOME}
          ;; 
        "")
          # blank line - skip
          ;;      
        *)
          #
          # Set ORACLE_HOME and ORACLE_SID
          #
          OSID="`echo $OLINE | awk -F: '{print $1}' -`"
          OHOME="`echo $OLINE | awk -F: '{print $2}' -`"
          #
          printf "Alias: %-13s %18s\n" ${OSID} ${OHOME}
          ;;
      esac
    done < $GBL_ORATAB
  else
    echo "No oratab found at: $GBL_ORATAB"
    RC=1
  fi
  #
  echo " "
  #
  return $RC
}
#########################################################################################
#
# SETLVAR - Set any local variables defined in DEPVAR
#
#########################################################################################
function SETLVAR {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  typeset CTR=1
  typeset TMPVAR
  #
  # Save original IFS (e.g. defaults to <space><tab><newline>)
  typeset OIFS=$IFS
  #
  # Set IFS and parse the current date
  typeset IFS="!%"
  #
  # Set each defined local variable
  #
  while true
  do
    eval TMPVAR='$LVAR'${CTR}
    if [ -n "$TMPVAR" ]; then
      export `echo $TMPVAR`
    else
      break
    fi
    let CTR=CTR+1
  done
  #
  # Restore original IFS
  #
  IFS=$OIFS
  #
  return $RC
}
#########################################################################################
#
# UNSETLVAR - Unset any local variables defined in DEPVAR
#             Argument: VAR - Unset variable defined by the local variable
#                       LVAR - Unset the local variable itself (used at end of script)
#
#########################################################################################
function UNSETLVAR {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset arg1="${1}"
  typeset RC=0
  typeset CTR=1
  typeset TMPVAR
  #
  # Unset each defined local variable
  #
  while true
  do
    eval TMPVAR='$LVAR'${CTR}
    if [ -n "$TMPVAR" ]; then
      if [ "${arg1}" = "LVAR" ]; then
        unset 'LVAR'${CTR}
      else
        unset `echo $TMPVAR | awk -F= '{print $1}' -`
      fi
    else
      break
    fi
    let CTR=CTR+1
  done
  #
  return $RC
}
#########################################################################################
#########################################################################################
#
# dbcontrol functions
#
#########################################################################################
#
# UNSETVAR - Unsets environment variables
#
#########################################################################################
function UNSETVAR {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset arg1="${1}"
  #
  typeset RC=0
  typeset ULINE
  typeset util
  typeset STRIP_HOME
  #
  # Process utility entries
  #
  while read ULINE; do
    util="`echo $ULINE | awk -F: '{print $1}' -`"
    case $util in
      "#NETV1"|"#SNET"|"#NAMES"|"#AGENT"|"#OID"|"#OEM"|"#OWS3"|"#OC4J"|"#AS9"|"#AS10"|"#WL11"|"#OCA"|"#GC10"|"#HTTP"|"#CRS"|"#GRID")
        # Handle utilities
        STRIP_HOME="`echo $ULINE | awk -F: '{print $2}' -`"
        # 
        # Strip ORACLE_HOME from the PATH
        #
        # PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}'/bin;;g'`
        PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
        LD_LIBRARY_PATH=`echo ${LD_LIBRARY_PATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
        LD_LIBRARY_PATH_32=`echo ${LD_LIBRARY_PATH_32} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
        LD_LIBRARY_PATH_64=`echo ${LD_LIBRARY_PATH_64} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
        SHLIB_PATH=`echo ${SHLIB_PATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
        MANPATH=`echo ${MANPATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
        #
        # Unset Application Server specifics
        #
        case $util in
          "#OC4J"|"#AS9"|"#AS10"|"#GC10"|"#HTTP")
            if [ "$util" = "#AS9" ]; then
              #
              # Remove 9i AS utilities from the PATH
              #
              PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}/Apache/Apache/bin'/[^:$]*;;g'`
              PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}/dcm/bin'/[^:$]*;;g'`
            elif [ "$util" = "#AS10" ] || [ "$util" = "#GC10" ] || [ "$util" = "#HTTP" ]; then
              #
              # Remove 10g AS utilities from the PATH
              #
              PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}/Apache/Apache/bin'/[^:$]*;;g'`
              PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}/dcm/bin'/[^:$]*;;g'`
              PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}/opmn/bin'/[^:$]*;;g'`
            fi
          ;;
        esac
        ;;
      \#*)
        # comment-line in oratab - skip
        ;;
      "")
        # blank line - skip
        ;;
      \*|*) 
        # Process databases
        STRIP_HOME="`echo $ULINE | awk -F: '{print $2}' -`"
        if [ $? -eq 0 ] && [ -n "${STRIP_HOME}" ]; then
          # 
          # Strip ORACLE_HOME from the PATH
          #
          # PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}'/bin;;g'`
          PATH=`echo ${PATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
          LD_LIBRARY_PATH=`echo ${LD_LIBRARY_PATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
          LD_LIBRARY_PATH_32=`echo ${LD_LIBRARY_PATH_32} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
          LD_LIBRARY_PATH_64=`echo ${LD_LIBRARY_PATH_64} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
          SHLIB_PATH=`echo ${SHLIB_PATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
          MANPATH=`echo ${MANPATH} | sed 's;'${STRIP_HOME}'/[^:$]*;;g'`
        fi
      ;;
    esac
  done < $GBL_ORATAB
  #
  # Remove GBL_LDPATH/GBL_LDPATH64
  #
  if [ -n "${GBL_LDPATH}" ]; then
    LD_LIBRARY_PATH=`echo ${LD_LIBRARY_PATH} | sed 's;'${GBL_LDPATH}';;g'`
    LD_LIBRARY_PATH_32=`echo ${LD_LIBRARY_PATH_32} | sed 's;'${GBL_LDPATH}';;g'`
    LD_LIBRARY_PATH_64=`echo ${LD_LIBRARY_PATH_64} | sed 's;'${GBL_LDPATH}';;g'`
    SHLIB_PATH=`echo ${SHLIB_PATH} | sed 's;'${GBL_LDPATH}';;g'`
  fi
  #
  if [ -n "${GBL_LDPATH64}" ]; then
    LD_LIBRARY_PATH=`echo ${LD_LIBRARY_PATH} | sed 's;'${GBL_LDPATH64}';;g'`
    LD_LIBRARY_PATH_64=`echo ${LD_LIBRARY_PATH_64} | sed 's;'${GBL_LDPATH64}';;g'`
  fi
  #
  # Remove leading colon if left over from above
  #
  PATH="`echo ${PATH} | sed 's/^:\(.*\)/\1/'`"
  LD_LIBRARY_PATH="`echo ${LD_LIBRARY_PATH} | sed 's/^:\(.*\)/\1/'`"
  LD_LIBRARY_PATH_32="`echo ${LD_LIBRARY_PATH_32} | sed 's/^:\(.*\)/\1/'`"
  LD_LIBRARY_PATH_64="`echo ${LD_LIBRARY_PATH_64} | sed 's/^:\(.*\)/\1/'`"
  SHLIB_PATH="`echo ${SHLIB_PATH} | sed 's/^:\(.*\)/\1/'`"
  MANPATH="`echo ${MANPATH} | sed 's/^:\(.*\)/\1/'`"
  #
  # The following removes any multiple colons
  #
  PATH="`echo ${PATH} | sed 's;:*:;:;g'`"
  LD_LIBRARY_PATH="`echo ${LD_LIBRARY_PATH} | sed 's;:*:;:;g'`"
  LD_LIBRARY_PATH_32="`echo ${LD_LIBRARY_PATH_32} | sed 's;:*:;:;g'`"
  LD_LIBRARY_PATH_64="`echo ${LD_LIBRARY_PATH_64} | sed 's;:*:;:;g'`"
  SHLIB_PATH="`echo ${SHLIB_PATH} | sed 's;:*:;:;g'`"
  MANPATH="`echo ${MANPATH} | sed 's;:*:;:;g'`"
  #
  # The following removes trailing colon if there
  #
  PATH="`echo ${PATH} | sed 's/\(.*\):$/\1/'`"
  LD_LIBRARY_PATH="`echo ${LD_LIBRARY_PATH} | sed 's/\(.*\):$/\1/'`"
  LD_LIBRARY_PATH_32="`echo ${LD_LIBRARY_PATH_32} | sed 's/\(.*\):$/\1/'`"
  LD_LIBRARY_PATH_64="`echo ${LD_LIBRARY_PATH_64} | sed 's/\(.*\):$/\1/'`"
  SHLIB_PATH="`echo ${SHLIB_PATH} | sed 's/\(.*\):$/\1/'`"
  MANPATH="`echo ${MANPATH} | sed 's/\(.*\):$/\1/'`"
  #
  # Export variables if set
  #
  if [ -n "${PATH}" ]; then
    export PATH
  else
    unset PATH
  fi
  #
  if [ -n "${LD_LIBRARY_PATH}" ]; then
    export LD_LIBRARY_PATH
  else
    unset LD_LIBRARY_PATH
  fi
  #
  if [ -n "${LD_LIBRARY_PATH_32}" ]; then
    export LD_LIBRARY_PATH_32
  else
    unset LD_LIBRARY_PATH_32
  fi
  #
  if [ -n "${LD_LIBRARY_PATH_64}" ]; then
    export LD_LIBRARY_PATH_64
  else
    unset LD_LIBRARY_PATH_64
  fi
  #
  if [ -n "${SHLIB_PATH}" ]; then
    export SHLIB_PATH
  else
    unset SHLIB_PATH
  fi
  #
  if [ -n "${MANPATH}" ]; then
    export MANPATH
  else
    unset MANPATH
  fi
  #
  # Unset all other environment variables
  #
  # Don't unset ORACLE_SID if an argument was passed
  #
  if [ -z "$arg1" ]; then
    unset ORACLE_SID
  fi
  unset ORACLE_HOME
  unset ORACLE_UNQNAME
  #
  unset EPC_DISABLED
  unset TWO_TASK
  unset ORACLE_TERM
  #
  unset ORA_NLS
  unset ORA_NLS32
  unset ORA_NLS33
  unset ORA_NLS10
  unset ORA_TZFILE
  #
  unset ORAWEB_HOME
  unset ORAWEB_SITE
  unset ORAWEB_ADMIN
  #
  unset J2EE_HOME
  unset DOMAIN_HOME
  unset WL_HOME
  unset WLS_HOME
  unset NODEMGR_HOME
  unset SERVER_NAME
  #
  unset BKUPID
  #
  return $RC
}
#########################################################################################
#
# SETPATH - Set the PATH for tool support
#
#########################################################################################
function SETPATH {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset arg1="${1}"
  #
  typeset RC=0
  #
  if [ -n "${GBL_LBIN}" ]; then
    if [ "$arg1" = "UNSET" ]; then
      if [ `echo $PATH | grep -i ${GBL_LBIN}` ]; then
        #
        # Remove local bin directories
        # Note: We don't parse for individual directories, this expects
        #       that the directories were set together with GBL_LBIN
        #
        PATH=`echo $PATH | sed 's;'${GBL_LBIN}';;g'`
        #
        # The following removes any leading, multiple or trailing colons
        #
        PATH="`echo ${PATH} | sed 's/^:\(.*\)/\1/' | sed 's;:*:;:;g' | sed 's/\(.*\):$/\1/'`"
      fi
    else
      #
      # Make sure the local bin directory is in the path
      #
      if [ `echo $PATH | grep -i ${GBL_LBIN}` ]; then
        # Local bin directories are already in the PATH
        :
      else
        # Add local bin directories to the PATH
        PATH="${GBL_LBIN}:${PATH}"
        export PATH
      fi
    fi
  fi
  #
  return $RC
}
#########################################################################################
#
# SETLDPATH - Set LD_LIBRARY_PATH/SHLIB_PATH
#
#########################################################################################
function SETLDPATH {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  #
  # Set 32-bit or 64-bit libraries based on port and version - Oracle8 specific
  #
  if [ "$GBL_MAJ_VER" -eq 8 ]; then
    case $GBL_PORT in
      "HP-UX" )
        if [ -d "$ORACLE_HOME/lib64" ]; then
          if [ -n "${GBL_LDPATH64}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH64}:${ORACLE_HOME}/lib64"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib64"
          fi
        elif [ -d "$ORACLE_HOME/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        #
        if [ -d "$ORACLE_HOME/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            SHLIB_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            SHLIB_PATH="${ORACLE_HOME}/lib"
          fi
        fi
        ;;
      "SunOS" )
        if [ -d "$ORACLE_HOME/lib64" ]; then
          if [ -n "${GBL_LDPATH64}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH64}:${ORACLE_HOME}/lib64"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib64"
          fi
          #
          if [ -d "$ORACLE_HOME/lib" ]; then
            if [ -n "${GBL_LDPATH}" ]; then
              LD_LIBRARY_PATH_32="${GBL_LDPATH}:${ORACLE_HOME}/lib"
            else
              LD_LIBRARY_PATH_32="${ORACLE_HOME}/lib"
            fi
          else
            if [ -n "${GBL_LDPATH}" ]; then
              LD_LIBRARY_PATH_32="${GBL_LDPATH}"
            fi
          fi
        elif [ -d "$ORACLE_HOME/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
      "Linux" )
        if [ -d "$ORACLE_HOME/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
      * )
        if [ -d "$ORACLE_HOME/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
    esac
  #
  # Oracle 9i (assume 10g/11g is handled the same)
  #
  elif [ "$GBL_MAJ_VER" -eq 9 ] || [ "$GBL_MAJ_VER" -eq 10 ] ||
       [ "$GBL_MAJ_VER" -eq 11 ]; then
    case $GBL_PORT in
      "HP-UX" )
        if [ -d "$ORACLE_HOME/lib" ]; then
          if [ -n "${GBL_LDPATH64}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH64}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH64}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH64}"
          fi
        fi
        #
        if [ -d "$ORACLE_HOME/lib32" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            SHLIB_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib32"
          else
            SHLIB_PATH="${ORACLE_HOME}/lib32"
          fi
        else
          SHLIB_PATH="${GBL_LDPATH}"
        fi
        ;;
      "SunOS" )
        if [ -d "$ORACLE_HOME/lib64" ]; then
          if [ -n "${GBL_LDPATH64}" ]; then
            LD_LIBRARY_PATH_64="${GBL_LDPATH64}:${ORACLE_HOME}/lib64"
          else
            LD_LIBRARY_PATH_64="${ORACLE_HOME}/lib64"
          fi
        fi
        #
        if [ -d "$ORACLE_HOME/lib32" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib32"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib32"
          fi
        else
          if [ -d "$ORACLE_HOME/lib" ]; then
            if [ -n "${GBL_LDPATH}" ]; then
              LD_LIBRARY_PATH="${GBL_LDPATH}"
            else
              LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
            fi
          else
            if [ -n "${GBL_LDPATH}" ]; then
              LD_LIBRARY_PATH="${GBL_LDPATH}"
            fi
          fi
        fi
        ;;
      "Linux" )
        if [ -d "$ORACLE_HOME/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
      * )
        if [ -d "${ORACLE_HOME}/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
    esac
    #
    # Add Oracle Text library if it exists
    #
    if [ "$GBL_MAJ_VER" -eq 9 ] || [ "$GBL_MAJ_VER" -eq 10 ] ||
       [ "$GBL_MAJ_VER" -eq 11 ]; then 
      if [ -d "${ORACLE_HOME}/ctx/lib" ]; then
        LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${ORACLE_HOME}/ctx/lib"
      fi
    fi
  else
    #
    # Catch any other database versions
    #
    case $GBL_PORT in
      "HP-UX")
        if [ -d "${ORACLE_HOME}/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
            SHLIB_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
            SHLIB_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
            SHLIB_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
      "SunOS")
        if [ -d "${ORACLE_HOME}/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
      "Linux")
        if [ -d "${ORACLE_HOME}/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
      *)
        if [ -d "${ORACLE_HOME}/lib" ]; then
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}:${ORACLE_HOME}/lib"
          else
            LD_LIBRARY_PATH="${ORACLE_HOME}/lib"
          fi
        else
          if [ -n "${GBL_LDPATH}" ]; then
            LD_LIBRARY_PATH="${GBL_LDPATH}"
          fi
        fi
        ;;
    esac
  fi
  #
  # Export settings 
  #
  if [ -n "${LD_LIBRARY_PATH}" ]; then
    export LD_LIBRARY_PATH
  fi
  #
  if [ -n "${LD_LIBRARY_PATH_32}" ]; then
    export LD_LIBRARY_PATH_32
  fi
  #
  if [ -n "${LD_LIBRARY_PATH_64}" ]; then
    export LD_LIBRARY_PATH_64
  fi
  #
  if [ -n "${SHLIB_PATH}" ]; then
    export SHLIB_PATH
  fi
  #
  return $RC
}
#########################################################################################
#
# SET73LD - Set additional libraries for Solaris Version 7.3 LD_LIBRARY_PATH
#
#########################################################################################
function SET73LD {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  #
  # Solaris 7.3.3 requires an additional library in LD_LIBRARY_PATH
  #
  if [ `echo $LD_LIBRARY_PATH | grep $ORACLE_HOME/lib/libXm_sol2\.4` ]; then
    # Already correct, we're done
    :
  else
    # Solaris and 7.3.3 specific
    if [ -d "$ORACLE_HOME/lib/libXm_sol2.4" ]; then
      # The following removes trailing colon and adds library
      LD_LIBRARY_PATH="`echo $LD_LIBRARY_PATH | sed 's/\(.*\):$/\1/'`:$ORACLE_HOME/lib/libXm_sol2.4"
      export LD_LIBRARY_PATH
    fi
  fi
  #
  return $RC
}
#########################################################################################
#
# SETNLS - Set NLS variables
#
#########################################################################################
function SETNLS {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  # 
  # Set NLS Environment, depends on ORACLE_HOME version naming of the format 7.3.4
  # (e.g. /oracle/product/7.3.4)
  #
  if [ "$GBL_MAJ_VER" -eq 7 ] && [ "$GBL_MIN_VER" -eq 2 ]; then
    if [ -d "$ORACLE_HOME/ocommon/nls/admin/data" ]; then
      ORA_NLS="$ORACLE_HOME/ocommon/nls/admin/data"
      export ORA_NLS
    fi
  elif [ "$GBL_MAJ_VER" -eq 7 ] && [ "$GBL_MIN_VER" -eq 3 ]; then
    if [ -d "$ORACLE_HOME/ocommon/nls/admin/data" ]; then
      ORA_NLS32="$ORACLE_HOME/ocommon/nls/admin/data"
      export ORA_NLS32
      # Add for D2K 1.6, in addition to previous setting
      if [ -d "$ORACLE_HOME/ocommon/nls/admin/datad2k" ]; then
        ORA_NLS33="$ORACLE_HOME/ocommon/nls/admin/datad2k"
        export ORA_NLS33
      fi
    fi   
  elif [ "$GBL_MAJ_VER" -eq 8 ] || [ "$GBL_MAJ_VER" -eq 9 ]; then
    if [ -d "$ORACLE_HOME/ocommon/nls/admin/data" ]; then
      ORA_NLS33="$ORACLE_HOME/ocommon/nls/admin/data"
      export ORA_NLS33
      # Add for D2K 1.6, override previous setting
      if [ -d "$ORACLE_HOME/ocommon/nls/admin/datad2k" ]; then
        ORA_NLS33="$ORACLE_HOME/ocommon/nls/admin/datad2k"
        export ORA_NLS33
      fi
    fi
  elif [ "$GBL_MAJ_VER" -eq 10 ] || [ "$GBL_MAJ_VER" -eq 11 ]; then
    # See Note: 292942.1 - Language and Territory definitions changed in
    # 10g and up versus 9i and lower
    if [ -d "$ORACLE_HOME/nls/data/9idata" ]; then
      ORA_NLS10="$ORACLE_HOME/nls/data/9idata"
      export ORA_NLS10
    elif [ -d "$ORACLE_HOME/nls/data" ]; then
      ORA_NLS10="$ORACLE_HOME/nls/data"
      export ORA_NLS10
    else
      if [ -d "$ORACLE_HOME/ocommon/nls/admin/data" ]; then
        ORA_NLS33="$ORACLE_HOME/ocommon/nls/admin/data"
        export ORA_NLS33
        # Add for D2K 1.6, override previous setting
        if [ -d "$ORACLE_HOME/ocommon/nls/admin/datad2k" ]; then
          ORA_NLS33="$ORACLE_HOME/ocommon/nls/admin/datad2k"
          export ORA_NLS33
        fi
      fi
    fi
  else
    # Catch all to set ORA_NLS if all else fails
    if [ -d "$ORACLE_HOME/ocommon/nls/admin/data" ]; then
      ORA_NLS="$ORACLE_HOME/ocommon/nls/admin/data"
      export ORA_NLS
    fi
  fi
  #
  return $RC
}
#########################################################################################
#
# SETOSH - Check and run the osh utility if needed
#          osh is an Oracle supplied utility to check and raise the ulimit to the maximum
#          if necessary. This is run by both oraenv and coraenv and is included in
#          orasetup to insure compatibility with those scripts.
#
#########################################################################################
function SETOSH {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  typeset ULIMIT
  #
  # Check ulimit and run osh if not "unlimited"
  #
  ULIMIT=`LANG=C ulimit 2>/dev/null`
  if [ $? -eq 0 ]; then
    if [ "$ULIMIT" != "unlimited" ]; then
      if [ "$ULIMIT" -lt 2113674 ]; then
        if [ -f "$ORACLE_HOME/bin/osh" ]; then
          exec $ORACLE_HOME/bin/osh
          RC=$?
        else
          which osh > /dev/null 2>&1
          if [ $? -eq 0 ]; then
            exec osh
            RC=$?
          else
            RC=1
          fi
        fi
      fi
    fi
  else
    echo "Error checking ulimit"
    RC=1
  fi
  #
  return $RC
}
#########################################################################################
#
# SETMISC - Set miscellaneous environment variables
#
#########################################################################################
function SETMISC {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset arg1="${1}"
  typeset RC=0
  typeset ENVFIL
  #
  # Set local bin directories in PATH
  #
  SETPATH
  if [ $? -ne 0 ]; then
    echo "Error setting local bin directories in \$PATH"
    RC=1
  fi
  #
  # Set tool environment
  # NOTE: Since this has become dependent on platform and port we now test and
  #       invoke the appropriate functions.  Assumes an ORACLE_HOME with at least
  #       a 3 digit version number consistent with OFA standards.
  #
  ORACLE_TERM=$GBL_OTERM
  export ORACLE_TERM
  #
  # Disable Oracle Trace for SQL*Net connections
  #
  if [ "$GBL_MAJ_VER" -le 9 ]; then
    EPC_DISABLED=TRUE
    export EPC_DISABLED
  fi
  #
  SETLDPATH
  if [ $? -ne 0 ]; then
    echo "Error setting \$LD_LIBRARY_PATH"
    RC=1
  else
    #
    # SunOS specific setup
    if [ $GBL_PORT = "SunOS" ]; then
      if [ "$GBL_MAJ_VER" -eq 7 ] && [ "$GBL_MIN_VER" -eq 3 ]; then
        SET73LD
        if [ $? -ne 0 ]; then
          echo "Error setting Oracle 7.3 \$LD_LIBRARY_PATH"
          RC=1
        fi
      fi
    fi
  fi
  #
  # Override LD_LIBRARY_PATH setting for Solaris 64-bit bug with oemctrl and jre
  #
  if [ "${GBL_PORT}" = "SunOS" ] && [ "${ORACLE_SID}" = "#OEM" ]; then
    if [ -n "${LD_LIBRARY_PATH_32}" ]; then
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH_32}
      export LD_LIBRARY_PATH
      unset LD_LIBRARY_PATH_32
    fi
  fi
  #
  # Set NLS environment
  #
  SETNLS
  if [ $? -eq 1 ]; then
    echo "Error setting NLS environment variables"
    RC=1
  fi
  #
  # Set BKUPID if bkctrl utility exists
  #
  if [ -r "${GBL_BKUPCFG}/${arg1}.config" ]; then
    export BKUPID=${arg1}
  fi
  #
  # Use 11i environment setup files
  #
  # The first test looks for pre 11.5.9 format, and the second
  # test looks for 11.5.9+ format.
  #
  if [ -n "${ORACLE_SID}" ]; then
    ENVFIL=${ORACLE_SID}
  elif [ -n "${TWO_TASK}" ]; then
    ENVFIL=${TWO_TASK}
  fi
  #
  if [ -n "$ENVFIL" ] && [ `echo $ENVFIL | cut -b 1` != '#' ]; then
    typeset HOST=`hostname`
    if [ -r "${ORACLE_HOME}/${ENVFIL}.env" ]; then
      . ${ORACLE_HOME}/${ENVFIL}.env
      if [ $? -ne 0 ]; then
        echo "Error setting 11i environment variables"
        RC=1
      fi
    elif [ -r "${ORACLE_HOME}/${ENVFIL}_${HOST}.env" ]; then
      . ${ORACLE_HOME}/${ENVFIL}_${HOST}.env
      if [ $? -ne 0 ]; then
        echo "Error setting 11i environment variables"
        RC=1
      fi
    fi
  fi
  #
  # Invoke a user defined environment script if it exists
  #
  if [ -n "$GBL_USERENV" ] && [ -r "$GBL_USERENV/${ENVFIL}.env" ]; then
    . $GBL_USERENV/${ENVFIL}.env
    if [ $? -ne 0 ]; then
      echo "Error running user defined environment script: $GBL_USERENV/${ENVFIL}.env"
      RC=1
    fi
  fi
  #
  # Run the osh utility if necessary
  #
  if [ "$GBL_OSH" -eq 1 ]; then
    SETOSH
    if [ $? -eq 1 ]; then
      echo "Error running osh utility"
      RC=1
    fi
  fi
  #
  return $RC
}
#########################################################################################
#########################################################################################
#
# end of dbcontrol functions
#
#########################################################################################
#
# SETSID - Set ORACLE_SID
#
#########################################################################################
function SETSID {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset arg1="${1}"
  typeset arg2="${2}"
  typeset RC=0
  typeset LINE
  typeset TMPFIL="/tmp/setsid.$$"
  #
  # Default to "*" entries if no SID is passed
  #
  if [ -z "${arg1}" ]; then
    arg1="*"
  fi
  #
  # Enforces SID at beginning of line, but ignores case
  # Checks to see if at least one SID exists - NOTE for utility entries (e.g. SNET, OEM)
  # there may be more than one entry.
  #
  grep -i "^${arg1}:.*${arg2}" ${GBL_ORATAB} > $TMPFIL
  if [ $? -eq 0 ]; then
    while read LINE; do
      ORACLE_SID="`echo $LINE | awk -F: '{print $1}' -`"
      if [ $? -ne 0 ]; then
        RC=1
      else
        export ORACLE_SID
      fi
      break
    done < $TMPFIL
  else
    RC=1
  fi
  rm -f $TMPFIL
  #
  return $RC
}
#########################################################################################
#
# SETHOME - Set ORACLE_HOME
#
#########################################################################################
function SETHOME {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset arg1="${1}"
  typeset RC=0
  typeset LINE
  typeset TMPFIL="/tmp/sethome.$$"
  #
  # Use a while loop to handle multiple entries (e.g. SNET)
  grep -i "^${ORACLE_SID}:.*${arg1}" ${GBL_ORATAB} > $TMPFIL
  if [ $? -eq 0 ]; then
    while read LINE; do
      ORACLE_HOME="`echo $LINE | awk -F: '{print $2}' -`"
      if [ $? -ne 0 ]; then
        RC=1
      else
        if [ -d "$ORACLE_HOME" ]; then
          export ORACLE_HOME
          #  echo " ++ ORACLE_HOME is " $ORACLE_HOME
          #
          # Set major/minor version
          #
          if [ `echo $ORACLE_HOME | grep '7\.[0-9]\.[0-9]*'` ]; then
            GBL_MAJ_VER=7
            GBL_MIN_VER="`echo $ORACLE_HOME | sed 's/.*7\.\(.\).*/\1/'`"
          elif [ `echo $ORACLE_HOME | grep '8\.[0-9]\.[0-9]*'` ]; then
            GBL_MAJ_VER=8
            GBL_MIN_VER="`echo $ORACLE_HOME | sed 's/.*8\.\(.\).*/\1/'`"
          elif [ `echo $ORACLE_HOME | grep '9\.[0-9]\.[0-9]*'` ]; then
            GBL_MAJ_VER=9
            GBL_MIN_VER="`echo $ORACLE_HOME | sed 's/.*9\.\(.\).*/\1/'`"
          elif [ `echo $ORACLE_HOME | grep '10\.[0-9]\.[0-9]*'` ]; then
            GBL_MAJ_VER=10
            GBL_MIN_VER="`echo $ORACLE_HOME | sed 's/.*10\.\(.\).*/\1/'`"
          elif [ `echo $ORACLE_HOME | egrep 'db10g|oms10g|agent10g'` ]; then
            GBL_MAJ_VER=10
            GBL_MIN_VER=0
          elif [ `echo $ORACLE_HOME | grep '11\.[0-9]\.[0-9]*'` ]; then
            GBL_MAJ_VER=11
            GBL_MIN_VER="`echo $ORACLE_HOME | sed 's/.*11\.\(.\).*/\1/'`"
          else 
            GBL_MAJ_VER=0
            GBL_MIN_VER=0
          fi
          #
          # Test for TWO_TASK
          #
          if [ "`echo $LINE | awk -F: '{print $3}' -`" ]; then
            if [ "`echo $LINE | awk -F: '{print $3}' - | cut -b 1`" = "N" ]; then
              RC=2
            fi
          fi

        else
          RC=1
        fi
      fi
      break
    done < $TMPFIL
    #
    # The following adds $ORACLE_HOME/bin to the PATH
    #
    if [ -d "${ORACLE_HOME}/bin" ]; then
      PATH="${PATH}:${ORACLE_HOME}/bin"
      export PATH
    fi
  else
    RC=1
  fi
  rm -f $TMPFIL
  #
  return $RC
}
#########################################################################################
#
# SETNSR - Set NSR variables for backup system - Legato (EBU/RMAN)
#
#########################################################################################
function SETNSR {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  # 
  typeset LINE
  typeset RC=1  # Return 1 if nothing is set, 0 otherwise
  typeset TMPFIL="/tmp/setnsr.$$"
  #
  # Set NSR variables if possible
  if [ -r $GBL_BKUPCFG/${ORACLE_SID}.config ]; then
    # Assumes bkctrl config file which prefaces an export command
    grep "NSR" $GBL_BKUPCFG/${ORACLE_SID}.config > $TMPFIL
    if [ $? -eq 0 ]; then
      while read LINE; do
        eval $LINE
      done < $TMPFIL
      RC=0
    else
      echo " "
      echo "Error reading NSR variables from file: $GBL_BKUPCFG/${ORACLE_SID}.config"
      echo " "
    fi
    rm -f $TMPFIL
  fi
  return ${RC}
}
#########################################################################################
#
# SETBACK - Set EBU/OBACK HOME
#
#########################################################################################
function SETBACK {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  typeset arg1=${1}
  typeset TMPFIL="/tmp/setback.$$"
  #
  grep "^${arg1}:" ${GBL_ORATAB} > $TMPFIL
  if [ $? -eq 0 ]; then
    while read LINE; do
      if [ "${arg1}" = "#OBACK" ]; then
        # Set OBK_HOME
        OBK_HOME="`echo $LINE | awk -F: '{print $2}' -`/obackup"
        if [ -d "$OBK_HOME" ]; then
          export OBK_HOME
          # Set PATH
          if [ -d "${OBK_HOME}/bin" ]; then
            PATH=${OBK_HOME}/bin:${PATH}
            export PATH
          else
            RC=1
          fi
        else
          RC=1
        fi
        #
        # Set LD Search Path
        #
        if [ -d "${OBK_HOME}/lib" ]; then
          if [ -z "${LD_LIBRARY_PATH}" ]; then
            LD_LIBRARY_PATH=${OBK_HOME}/lib
          else      
            LD_LIBRARY_PATH=${OBK_HOME}/lib:${LD_LIBRARY_PATH}
          fi
          if [ -z "${SHLIB_PATH}" ]; then
            SHLIB_PATH=${OBK_HOME}/lib
          else
            SHLIB_PATH=${OBK_HOME}/lib:${SHLIB_PATH}
          fi
        else
          RC=1
        fi
        #
        if [ "$RC" -eq 0 ]; then
          echo " ++ obackup is: " $OBK_HOME
        fi
      elif [ "${arg1}" = "#EBU" ]; then
        # Set EBU_HOME
        EBU_HOME="`echo $LINE | awk -F: '{print $2}' -`/obackup"
        if [ -d "$EBU_HOME" ]; then
          export EBU_HOME
          # Set PATH
          if [ -d "${EBU_HOME}/bin" ]; then
            PATH=${EBU_HOME}/bin:${PATH}
            export PATH
          else
            RC=1
          fi
        else
          RC=1
        fi
        #
        # Set LD Search Path
        #
        if [ -d "${EBU_HOME}/lib" ]; then
          if [ -z "${LD_LIBRARY_PATH}" ]; then
            LD_LIBRARY_PATH=${EBU_HOME}/lib
          else
            LD_LIBRARY_PATH=${EBU_HOME}/lib:${LD_LIBRARY_PATH}
          fi
          if [ -z "${SHLIB_PATH}" ]; then
            SHLIB_PATH=${EBU_HOME}/lib
          else
            SHLIB_PATH=${EBU_HOME}/lib:${SHLIB_PATH}
          fi
        else
          RC=1
        fi
        #
        if [ "$RC" -eq 0 ]; then
          echo " ++ ebu is: " $EBU_HOME
        fi
      fi
      #
      export LD_LIBRARY_PATH
      export SHLIB_PATH
      break
    done < $TMPFIL
    #
    # Set NSR variables if possible
    SETNSR
  else
    echo "${arg1} not found in oratab" 
    return 1
  fi
  rm -f $TMPFIL  
  #
  return $RC
}
#########################################################################################
#
# UNSETBACK - Unset backup environment variables
#
#########################################################################################
function UNSETBACK {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=1  # Return 1 if nothing is unset, 0 otherwise
  typeset LINE
  typeset OBK_HOME
  typeset EBU_HOME
  typeset TMPFIL="/tmp/unsetback.$$"
  #
  # Unset any OBK directories
  grep "^#OBACK" ${GBL_ORATAB} > $TMPFIL
  if [ $? -eq 0 ]; then
    while read LINE; do
      OBK_HOME="`echo $LINE | awk -F: '{print $2}' -`"
      #
      # Remove OBK directories from PATH
      PATH=`echo ${PATH} | sed 's;'${OBK_HOME}'/obackup/bin;;g'`
      #
      # Remove OBK directories from LD_LIBRARY_PATH/SHLIB_PATH
      LD_LIBRARY_PATH=`echo ${LD_LIBRARY_PATH} | sed 's;'${OBK_HOME}'/obackup/lib;;g'`
      SHLIB_PATH=`echo ${SHLIB_PATH} | sed 's;'${OBK_HOME}'/obackup/lib;;g'`
      #
      RC=0
      break
    done < $TMPFIL
  fi
  rm -f $TMPFIL
  #
  # Unset any EBU directories  
  grep "^#EBU" ${GBL_ORATAB} > $TMPFIL
  if [ $? -eq 0 ]; then
    while read LINE; do
      EBU_HOME="`echo $LINE | awk -F: '{print $2}' -`"
      #
      # Remove EBU directories from PATH
      PATH=`echo ${PATH} | sed 's;'${EBU_HOME}'/obackup/bin;;g'`
      #
      # Remove EBU directories from LD_LIBRARY_PATH/SHLIB_PATH
      LD_LIBRARY_PATH=`echo ${LD_LIBRARY_PATH} | sed 's;'${EBU_HOME}'/obackup/lib;;g'`
      SHLIB_PATH=`echo ${SHLIB_PATH} | sed 's;'${EBU_HOME}'/obackup/lib;;g'`
      #
      unset EBU_HOME
      RC=0
      break
    done < $TMPFIL
  fi
  rm -f $TMPFIL
  #
  if [ "$RC" -eq 0 ]; then
    #
    # Remove leading colon if left over from above
    PATH="`echo ${PATH} | sed 's/^:\(.*\)/\1/'`"
    LD_LIBRARY_PATH="`echo ${LD_LIBRARY_PATH} | sed 's/^:\(.*\)/\1/'`"
    SHLIB_PATH="`echo ${SHLIB_PATH} | sed 's/^:\(.*\)/\1/'`"
    #
    # The following removes any multiple colons
    PATH="`echo ${PATH} | sed 's;:*:;:;g'`"
    LD_LIBRARY_PATH="`echo ${LD_LIBRARY_PATH} | sed 's;:*:;:;g'`"
    SHLIB_PATH="`echo ${SHLIB_PATH} | sed 's;:*:;:;g'`"
    #
    # The following removes trailing colon if there
    PATH="`echo ${PATH} | sed 's/\(.*\):$/\1/'`"
    LD_LIBRARY_PATH="`echo ${LD_LIBRARY_PATH} | sed 's/\(.*\):$/\1/'`"
    SHLIB_PATH="`echo ${SHLIB_PATH} | sed 's/\(.*\):$/\1/'`"
    #
    # Export variables if set
    #
    if [ -n "${PATH}" ]; then
      export PATH
    else
      unset PATH
    fi
    #
    if [ -n "${LD_LIBRARY_PATH}" ]; then
      export LD_LIBRARY_PATH
    else
      unset LD_LIBRARY_PATH
    fi
    #
    if [ -n "${SHLIB_PATH}" ]; then
      export SHLIB_PATH
    else
      unset SHLIB_PATH
    fi
  fi
  #
  return $RC
}
#########################################################################################
#
# MAIN - Run main program
#
#########################################################################################
function MAIN {
  case $ORACLE_TRACE in
    T)
      set -x
      ;;
  esac
  #
  typeset RC=0
  typeset RCODE=0
  #
  typeset arg
  typeset arg2
  typeset ASLINE
  typeset TMPFIL="/tmp/tmpfil.$$"
  #
  # Set global script variables
  #
  DEPVAR
  #
  # Read Command line
  #
  arg=$(echo ${1} | $GBL_TR '[:lower:]' '[:upper:]')
  #
  if [ $# -gt 1 ]; then
    arg2=${2}
  fi
  #
  if [ "$arg" = "HELP" ] || [ "$arg" = "?" ]; then
    VERSION
    HELPMSG
    HELPFULL
    return 0
  fi
  #
  if [ "$arg" = "VERSION" ]; then
    VERSION
    return 0
  fi
  #
  if [ "$arg" = "MENU" ]; then
    OMENU
    return $?
  fi
  #
  # Set local variables
  #
  SETLVAR
  if [ $? -eq 1 ]; then
    echo "Error setting local environment variables"
    return 1
  fi
  #
  SETPATH
  #
  if [ -r "$GBL_ORATAB" ]; then
    #
    # Check all utility labels to see if they've been used in the oratab file.
    # This allows the use of a label as an actual sid name.
    #
    case ${arg} in
      "NETV1"|"SNET"|"NAMES"|"AGENT"|"OID"|"OEM"|"OWS3"|"OC4J"|"AS9"|"AS10"|"WL11"|"OCA"|"GC10"|"HTTP"|"CRS"|"#GRID"|"OBACK"|"EBU")
        grep -i "^${arg}:" ${GBL_ORATAB} > /dev/null
        if [ $? -ne 0 ]; then
          arg="#${arg}"
        fi
        ;;
    esac
    #
    # Add command line processing to set ORACLE_SID
    #
    case ${arg} in
      "#NETV1"|"#SNET"|"#NAMES"|"#AGENT"|"#OID"|"#OEM"|"#OWS3"|"#OC4J"|"#AS9"|"#AS10"|"#WL11"|"#OCA"|"#GC10"|"#HTTP"|"#CRS"|"#GRID")
        #
        # For utilities this is used as a check that the label exists in the
        # oratab file
        #
        SETSID "${arg}" ${arg2}
        if [ $? -ne 0 ]; then 
          echo "Oracle utility not defined in the oratab file"
          HELPMSG
          RCODE=1
        else
          UNSETVAR ${arg}
          if [ $? -ne 0 ]; then 
            RCODE=1
          else
            UNSETBACK
            #
            # Set ORACLE_HOME
            #
            SETHOME ${arg2}
            RC=$?
            if [ "$RC" -eq 1 ]; then
              echo "Error setting ORACLE_HOME"
              RCODE=1
            fi
            #
            # Return code of 2 not valid here - ignored
            #
            # Set the rest of the environment
            SETMISC
            RC=$?
            if [ "$RC" -gt 0 ]; then
              echo "Error setting Oracle environment"
              RCODE=1
            fi
            #
            # Handle special cases
            #
            case ${arg} in
              "#OWS3")
                #
                # Support for Oracle Apps Web Server Version 3
                # Run the OWS specific environment script supplied by Oracle
                #
                if [ -f $ORACLE_HOME/ows/3.0/install/owsenv_bsh.sh ]; then
                  . $ORACLE_HOME/ows/3.0/install/owsenv_bsh.sh
                  RC=$?
                  if [ "$RC" -gt 0 ]; then
                    echo "Error running the OWS setup script"
                    RCODE=1
                  fi
                else
                  echo "Oracle supplied OWS setup script not found"
                  RCODE=1
                fi
                #
                unset ORACLE_SID
                ;;
              "#AS9"|"#AS10"|"#GC10"|"#HTTP"|"#OC4J")
                #
                # Support for 9i Application Server Setup
                # Add 9i AS utilities to the PATH
                #
                grep -i "^${arg}:.*${arg2}" ${GBL_ORATAB} > $TMPFIL
                if [ $? -eq 0 ]; then
                  while read ASLINE; do
                    TWO_TASK="`echo $ASLINE | awk -F: '{print $3}' - | cut -b 1`"
                    if [ -n "$TWO_TASK" ]; then
                      export TWO_TASK
                      unset ORACLE_SID
                      #
                      # Check to see if the database alias is set to Y or W in this oratab file
                      #
                      typeset DBFLAG="`grep ^${TWO_TASK} ${GBL_ORATAB} | awk -F: '{print $NF}' -`"
                      if [ "$DBFLAG" = "Y" ] || [ "$DBFLAG" = "W" ]; then
                        if [ "`grep ^${TWO_TASK} ${GBL_ORATAB} | awk -F: '{print $2}' -`" = "${ORACLE_HOME}" ]; then
                          ORACLE_SID=$TWO_TASK
                          export ORACLE_SID
                          unset TWO_TASK
                        fi
                      fi
                    else
                      unset ORACLE_SID
                      unset TWO_TASK
                    fi
                    #
                    break
                  done < $TMPFIL
                  #
                  # Handle each utility specific tasks here
                  #
                  case ${arg} in
                    "#AS9")
                      #
                      # The following adds 9i AS utilities to the PATH
                      #
                      PATH="${PATH}:${ORACLE_HOME}/Apache/Apache/bin:${ORACLE_HOME}/dcm/bin"
                      export PATH
                      ;;
                    "#AS10"|"#GC10"|"#HTTP")
                      #
                      # The following adds 10g AS utilities to the PATH
                      #
                      PATH="${PATH}:${ORACLE_HOME}/Apache/Apache/bin:${ORACLE_HOME}/dcm/bin:${ORACLE_HOME}/opmn/bin"
                      export PATH
                      #
                      # Only required for Relase 3, but it doesn't hurt anything to add it regardless
                      #
                      J2EE_HOME="${ORACLE_HOME}/j2ee/home"
                      export J2EE_HOME
                      #
                      # If 64-bit Linux then return code = 3
                      # ( Need to invoke 32-bit shell emulation )
                      #
                      if [ "$GBL_PORT" = "Linux" ]; then
                        if [ "`uname -m`" = "x86_64" ]; then
                          echo "Warning - Running 64-bit Linux"
                          echo "AS10, GC10 and HTTP options require 32-bit emulation mode"
                          echo "Set with the linux32 command"
                          RCODE=3
                        fi
                      fi
                      ;;
                    "#OC4J")
                      #
                      # Support for standalone OC4J
                      #
                      # Only required for Release 3, but it doesn't hurt anything to add it regardless
                      #
                      J2EE_HOME="${ORACLE_HOME}/j2ee/home"
                      export J2EE_HOME
                      ;;
                  esac
                else
                  echo "Error setting ${arg#\#} environment"
                  RCODE=1
                fi
                rm -f $TMPFIL
                ;;
              "#WL11")
                #
                # Support for 11g Fusion web server
                #
                if [ -d "${ORACLE_HOME}/user_projects/domains/base_domain" ]; then
                  DOMAIN_HOME="${ORACLE_HOME}/user_projects/domains/base_domain"
                  export DOMAIN_HOME
                  #
                  if [ -d "${DOMAIN_HOME}/bin" ]; then
                    PATH="${PATH}:${DOMAIN_HOME}/bin"
                    export PATH
                  fi
                fi
                #
                if [ -d "${ORACLE_HOME}/wlserver_10.3" ]; then
                  WL_HOME="${ORACLE_HOME}/wlserver_10.3"
                  export WL_HOME
                fi
                #
                if [ -d "${WL_HOME}/server" ]; then
                  WLS_HOME="${WL_HOME}/server"
                  export WLS_HOME
                  #
                  if [ -d "${WLS_HOME}/bin" ]; then
                    PATH="${PATH}:${WLS_HOME}/bin"
                    export PATH
                  fi
                fi
                #
                if [ -d "${WL_HOME}/common/nodemanager" ]; then
                  NODEMGR_HOME="${WL_HOME}/common/nodemanager"
                  export NODEMGR_HOME
                fi
                #
                grep -i "^${arg}:.*${arg2}" ${GBL_ORATAB} > $TMPFIL
                if [ $? -eq 0 ]; then
                  while read ASLINE; do
                    SERVER_NAME="`echo $ASLINE | awk -F: '{print $3}' -`"
                    if [ -n "$SERVER_NAME" ]; then
                        export SERVER_NAME
                    fi
                    #
                    break
                  done < $TMPFIL
                fi
                rm -f $TMPFIL
                #
                unset ORACLE_SID
                unset TWO_TASK
                ;;
              "#OEM")
                #
                # Support for Oracle 10g OEM dbconsole
                #
                if [ "$GBL_MAJ_VER" -lt 10 ]; then
                  unset ORACLE_SID
                else
                  #
                  # Checks to see if $arg2 exists as an entry for $arg (i.e. OEM) and if it
                  # does then sets it as the ORACLE_SID. Otherwise the first entry is used
                  # and if an alias exists it is used. Otherwise no ORACLE_SID is set since
                  # there's no way to no which database is intended. If 11.2 or greater then
                  # ORACLE_UNQNAME is also set.
                  #
                  grep -i "^${arg}:.*${arg2}" ${GBL_ORATAB} > $TMPFIL
                  if [ $? -eq 0 ]; then
                    while read ASLINE; do
                      if [ -n "${arg2}" ]; then
                        ORACLE_SID="${arg2}"
                        export ORACLE_SID
                      else
                        SERVER_NAME="`echo $ASLINE | awk -F: '{print $3}' -`"
                        if [ -n "$SERVER_NAME" ]; then
                          ORACLE_SID="$SERVER_NAME"
                          export ORACLE_SID
                        fi
                      fi
                      #
                      # If 11.2 then set ORACLE_UNQNAME
                      #
                      if [ -n "$ORACLE_SID" ]; then
                        if [ "$GBL_MAJ_VER" -ge 11 ] && [ "$GBL_MIN_VER" -ge 2 ]; then
                          ORACLE_UNQNAME="$ORACLE_SID"
                          export ORACLE_UNQNAME
                        fi
                      fi
                      #
                      break
                    done < $TMPFIL
                  else
                    unset ORACLE_SID
                  fi
                fi
                ;;
              *)
                #
                # Unset the ORACLE_SID for other utilities
                #
                unset ORACLE_SID
                ;;
            esac
          fi
        fi
        ;;
      "#OBACK"|"#EBU")
        UNSETBACK
        if [ $? -ne 0 ]; then 
          RCODE=1
        else
          SETBACK "${arg}"
          if [ $? -ne 0 ]; then 
            echo "Error setting ${arg} environment"
            HELPMSG
            RCODE=1
          fi
        fi
        ;;
      "UNSET")
        UNSETVAR
        if [ $? -ne 0 ]; then 
          RCODE=1
        else
          UNSETBACK
          UNSETLVAR
        fi
        ;;
      "OPATCH")
        if [ -d "${ORACLE_HOME}/OPatch" ]; then
          export PATH=${PATH}:${ORACLE_HOME}/OPatch
        else
          echo "OPatch directory not found. Make sure to set the database environment first."
          RCODE=1
        fi
        ;;
      "SSH")
        if [ -n "$GBL_SSH" ] && [ -r "$GBL_SSH/ssh.env" ]; then
          . $GBL_SSH/ssh.env
          if [ $? -ne 0 ]; then
            echo "Error running ssh equivalence script: $GBL_SSH/ssh.env"
            RCODE=1
          fi
        else
          echo "SSH equivalence script not found."
          RCODE=1
        fi
        ;;
      *)
        SETSID ${arg}
        if [ $? -ne 0 ]; then
          echo "Oracle database not found in the oratab file"
          HELPMSG
          RCODE=1
        else
          UNSETVAR "${ORACLE_SID}"
          if [ $? -ne 0 ]; then 
            RCODE=1
          else
            #
            # Set ORACLE_HOME
            SETHOME
            RC=$?
            if [ "$RC" -eq 1 ]; then
              echo "Error setting ORACLE_HOME"
              RCODE=1
            else
              if [ "${ORACLE_SID}" = "*" ]; then
                unset ORACLE_SID
              else
                if [ "$RC" -eq 2 ]; then
                  if [ "$GBL_OFLAG" -eq 1 ]; then
                    #
                    # Allow overriding original behavior that sets TWO_TASK when
                    # database startup flag is set to "N"
                    #
                    TWO_TASK=${ORACLE_SID}
                    export TWO_TASK
                    unset ORACLE_SID
                    # echo "ORACLE_SID unset and TWO_TASK is " $TWO_TASK
                    RCODE=2
                  fi
                fi
              fi
              #
              # Set the rest of the environment
              SETMISC ${ORACLE_SID}
              RC=$?
              if [ "$RC" -gt 0 ]; then
                echo "Error setting Oracle environment"
                RCODE=1
              fi
              #
              # Unsets any OBK/EBU variables and attempts to set
              # NSR variables for RMAN support
              if [ "$GBL_MAJ_VER" -eq 8 ] || [ "$GBL_MAJ_VER" -eq 9 ] ||
                 [ "$GBL_MAJ_VER" -eq 10 ] || [ "$GBL_MAJ_VER" -eq 11 ]; then
                UNSETBACK
                SETNSR
              fi
            fi
          fi
        fi
        ;;
    esac
  else
    echo "No oratab found at: $GBL_ORATAB"
    RCODE=1
  fi
  #
  return ${RCODE}
}
#########################################################################################
#
#  Program Begins Here
#
#########################################################################################
#
# Allow checking of unset environment variables
#
set +u
#
case $ORACLE_TRACE in
  T)
    set -x
    ;;
esac
#
typeset OS_RCODE=0
#
# Run main program
#
MAIN $@
OS_RCODE=$?
#
# Unset all variables if there was an error
#
if [ "$OS_RCODE" -ne 0 ] && [ "$OS_RCODE" -ne 2 ]; then
  UNSETLVAR
  SETPATH UNSET
  #
  if [ -r "$GBL_ORATAB" ]; then
    UNSETVAR
    UNSETBACK
  fi
fi
UNSETLVAR "LVAR"
#
# Unset global variables
#
unset GBL_LBIN
unset GBL_BKUPCFG
unset GBL_LDPATH
unset GBL_LDPATH64
unset GBL_TR
unset GBL_OTERM
unset GBL_OSH
unset GBL_ORATAB
unset GBL_PORT
unset GBL_USERENV
unset GBL_SSH
unset GBL_MAJ_VER
unset GBL_MIN_VER
unset GBL_OFLAG
#
# Unset functions as well (bash)
#
unset UNSETVAR SETSID SETHOME SETBACK UNSETBACK SETNSR SETMISC
unset SETLVAR UNSETLVAR SETPATH SETLDPATH SET73LD SETNLS SETOSH
unset VERSION HELPMSG HELPFULL OMENU DEPVAR MAIN
#
# Unset all positional parameters
#
set --
#
# Unset OS_RCODE and return its value
#
case $OS_RCODE in
  "0")
    unset OS_RCODE
    return 0
    ;;
  "1")
    unset OS_RCODE
    return 1
    ;;
  "2")
    unset OS_RCODE
    return 2
    ;;
  "3")
    unset OS_RCODE
    return 3
    ;;
esac
#
return $OS_RCODE
