#!/bin/sh

### LICENSE - (BSD 2-Clause) // ###
#
# Copyright (c) 2016, Daniel Plominski (ASS-Einrichtungssysteme GmbH)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
### // LICENSE - (BSD 2-Clause) ###

### ### ### ASS // ### ### ###

export TZ=Europe/Berlin

### stage0 // ###
SMARTOS=$(uname -a | egrep -c "SunOS|joyent")
HOURDATE=$(date "+%d%m%y-%H")

CONFIG="smartos-zone-backup.conf"
INCLUDE="smartos-zone-backup.include"
EXCLUDE="smartos-zone-backup.exclude"
LOGFILE="smartos-zone-backup.log"

GETSSHIP=$(grep -s "SSHIP" "$CONFIG" | sed 's/SSHIP=//g' | sed 's/"//g')
GETSSHUSER=$(grep -s "SSHUSER" "$CONFIG" | sed 's/SSHUSER=//g' | sed 's/"//g')
GETSSHPORT=$(grep -s "SSHPORT" "$CONFIG" | sed 's/SSHPORT=//g' | sed 's/"//g')
GETLOCALSSHKEY=$(grep -s "LOCALSSHKEY" "$CONFIG" | sed 's/LOCALSSHKEY=//g' | sed 's/"//g')
GETZFSDESTINATION=$(grep -s "ZFSDESTINATION" "$CONFIG" | sed 's/ZFSDESTINATION=//g' | sed 's/"//g')

PRG="$0"
##/ need this for relative symlinks
   while [ -h "$PRG" ] ;
   do
         PRG=$(readlink "$PRG")
   done
DIR=$(dirname "$PRG")
#
ADIR="$PWD"

#// FUNCTION: spinner (Version 1.0)
spinner() {
   local pid=$1
   local delay=0.01
   local spinstr='|/-\'
   while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
         local temp=${spinstr#?}
         printf " [%c]  " "$spinstr"
         local spinstr=$temp${spinstr%"$temp"}
         sleep $delay
         printf "\b\b\b\b\b\b"
   done
   printf "    \b\b\b\b"
}

#// FUNCTION: clean up tmp files (Version 1.0)
cleanup() {
   rm -rf /tmp/smartos_zone_backup*
}

#// FUNCTION: run script as root (Version 1.0)
checkrootuser() {
if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] This script must be run as root" 1>&2
   exit 1
fi
}

#// FUNCTION: check state (Version 1.0)
checkhard() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m   OK   \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;31m FAILED \033[0m\n")] '"$@"'"
   sleep 1
   exit 1
fi
}

#// FUNCTION: check state without exit (Version 1.0)
checksoft() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m   OK   \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;33m FAILED \033[0m\n")] '"$@"'"
   sleep 1
fi
}

#// FUNCTION: check state hidden (Version 1.0)
checkhiddenhard() {
if [ $? -eq 0 ]
then
   return 0
else
   checkhard "$@"
   return 1
fi
}

#// FUNCTION: check state hidden without exit (Version 1.0)
checkhiddensoft() {
if [ $? -eq 0 ]
then
   return 0
else
   checksoft "$@"
   return 1
fi
}

#// FUNCTION: check smartos-zone-backup config (Version 1.0)
checkconfig() {
if [ -s "$CONFIG" ]
then
   echo "[$(printf "\033[1;32m   OK   \033[0m\n")] using smartos-zone-backup config"
else
   echo "[$(printf "\033[1;33mSKIPPING\033[0m\n")] smartos-zone-backup config"
fi
}

#// FUNCTION: create snapshots (Version 1.0)
createsnap() {
   vmadm list | grep "stopped" | awk '{print $1}' > /tmp/smartos_zone_backup_1
   if [ -s /tmp/smartos_zone_backup_1 ]
   then
      echo "[$(printf "\033[1;32m   OK   \033[0m\n")] find stopped vms for backup purposes"
   else
      echo "[$(printf "\033[1;31m FAILED \033[0m\n")] can't find stopped vms"
      exit 1
   fi
   #// zones config backup
   cat /tmp/smartos_zone_backup_1 | xargs -L 1 -I % cp -p /etc/zones/%.xml /zones/%/
   checksoft zones config backup

   if [ -s "$EXCLUDE" ]
   then
      #// remove empty lines
      awk 'NF' "$EXCLUDE" > /tmp/smartos_zone_backup_exclude_1
      mv /tmp/smartos_zone_backup_exclude_1 "$EXCLUDE"

      zfs list | /usr/xpg4/bin/grep -f /tmp/smartos_zone_backup_1 | egrep -v "zones/cores" | awk '{print $1}' | /usr/xpg4/bin/grep -v -f "$EXCLUDE" | xargs -L 1 -I % zfs snapshot %@_SNAP_"$HOURDATE"
   else
      zfs list | /usr/xpg4/bin/grep -f /tmp/smartos_zone_backup_1 | egrep -v "zones/cores" | awk '{print $1}' | xargs -L 1 -I % zfs snapshot %@_SNAP_"$HOURDATE"
   fi
}

#// FUNCTION: list snapshots (Version 1.0)
listsnap() {
   echo "" # dummy
   echo "list created snapshots:"
   CHECKSNAPS=$(zfs list -t snapshot | grep "@_SNAP_" | wc -l | sed 's/ //g')
   if [ "$CHECKSNAPS" = "0" ]
   then
      echo "[$(printf "\033[1;31m FAILED \033[0m\n")] can't find any _SNAP_ snapshots, please use the backup command at first"
      exit 1
   fi
   zfs list -t snapshot | grep "@_SNAP_"
   echo "" # dummy
}

#// FUNCTION: send snapshots (Version 1.0)
sendsnap() {
   #// check ssh key login
   CHECKGETLOCALSSHKEY=$(grep -s "LOCALSSHKEY" "$CONFIG" | sed 's/LOCALSSHKEY=//g' | sed 's/"//g' | wc -l | sed 's/ //g')
   if [ "$CHECKGETLOCALSSHKEY" = "0" ]
   then
      zfs list -t snapshot -o name | grep "@_SNAP_" | xargs -L 1 -I % sh -c "zfs send % | ssh -p '"$GETSSHPORT"' '"$GETSSHUSER"'@'"$GETSSHIP"' zfs recv -Fv '"$GETZFSDESTINATION"'/%" 2> "$LOGFILE"
      checksoft hint: if zfs send fails partially please delete some old snapshots on the target
   else
      zfs list -t snapshot -o name | grep "@_SNAP_" | xargs -L 1 -I % sh -c "zfs send % | ssh -p '"$GETSSHPORT"' -i '"$GETLOCALSSHKEY"' '"$GETSSHUSER"'@'"$GETSSHIP"' zfs recv -Fv '"$GETZFSDESTINATION"'/%" 2> "$LOGFILE"
      checksoft hint: if zfs send fails partially please delete some old snapshots on the target
   fi
}

#// FUNCTION: clean up snapshots (Version 1.0)
cleansnap() {
   zfs list -t snapshot -o name | grep "@_SNAP_*" | xargs -L 1 -I % zfs destroy -v %
   checksoft remove all _SNAP_ snapshots
}

#// FUNCTION: sync buffer (Version 1.0)
syncbuffer() {
   sync
   checksoft sync buffer
}

### // stage0 ###

case "$1" in
### ### ### ### ### ### ### ### ###
'backup')
### stage1 // ###
case $SMARTOS in
   1)
### stage2 // ###
checkrootuser
cleanup
checkconfig
syncbuffer
### // stage2 ###

### stage3 // ###

createsnap
listsnap

### // stage3 ###
echo "" # dummy
printf "\033[1;32msmartos-zone-backup finished.\033[0m\n"
   ;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac

### // stage1 ###
   ;;
'send')
### stage1 // ###
case $SMARTOS in
   1)
### stage2 // ###
checkrootuser
cleanup
checkconfig
syncbuffer
### // stage2 ###

### stage3 // ###

listsnap
sendsnap

### // stage3 ###
echo "" # dummy
printf "\033[1;32msmartos-zone-backup finished.\033[0m\n"
   ;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac

### // stage1 ###
   ;;
'clean')
### stage1 // ###
case $SMARTOS in
1)
### stage2 // ###
checkrootuser
cleanup
checkconfig
syncbuffer
### // stage2 ###

### stage3 // ###

cleansnap

### // stage3 ###
echo "" # dummy
printf "\033[1;32msmartos-zone-backup finished.\033[0m\n"
   ;;
*)
   # error 1
   : # dummy
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac

### // stage1 ###
   ;;
### ### ### ### ### ### ### ### ###
*)
printf "\033[1;31mWARNING: smartos-zone-backup is experimental and its not ready for production. Do it at your own risk.\033[0m\n"
echo "" # usage
echo "usage: $0 { backup | send | clean }"
;;
esac
### ### ### // ASS ### ### ###
exit 0
# EOF
