#!/bin/bash
#
#

# Temporary Files
ctrlIndex=/tmp/ctrlIndex
devIndex=/tmp/devIndex
devList=/tmp/devList
poolDevList=/tmp/poolDevList
devListOutput=/tmp/devListOutputs


function print_help {
  echo "Please provide the ZFS pool name with the -p/--pool option"
  exit 0
}

function clean_tempfiles {
  if [ -e $ctrlIndex ]; then
    rm $ctrlIndex
  fi
  if [ -e $devIndex ]; then
    rm $devIndex
  fi
  if [ -e $devList ]; then
  rm $devList
  fi
  if [ -e $poolDevList ]; then
    rm $poolDevList
  fi
  if [ -e $devListOutput ]; then
    rm $devListOutput
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
    print_help
    ;;
    -p|--pool)
    zfsPool="$2"
    shift
    ;;
    *)
    break
    ;;
  esac
  shift
done

if [ -z ${zfsPool+x} ]; then
  print_help
fi

clean_tempfiles

sas3ircu list | sed -n '/Index/{n;n;p;}' | awk '{print $1'} > $ctrlIndex

for ctrl in $(cat $ctrlIndex); do
  sas3ircu $ctrl display > $devListOutput
  cat $devListOutput | awk -v ctrl=$ctrl '/Device is a Hard disk/ {printf ctrl";";getline;printf $4";";getline;printf $4";";getline;getline;getline;getline;getline;getline;getline;print $4}' >> $devIndex
done

 zpool status $zfsPool | awk '/gptid/,/ONLINE|AVAIL/ {print $1}' > $poolDevList

 if [ ${PIPESTATUS[0]} != 0 ]; then
   echo "Error: problem during the zpool status command for the pool $zfsPool"
   exit 0
 fi

 for gptid in $(cat $poolDevList); do
   devname=$(glabel status | awk -v gptid=$gptid '$0 ~ gptid {sub(/p.+/,"",$3); print $3}')
   serialnumber=$(camcontrol inquiry $devname | awk '/Serial Number/ {print $4}')
   cat $devIndex | awk -v serialnumber=$serialnumber -v devname=$devname -v gptid=$gptid '$0 ~ serialnumber {printf $0";"gptid";";print devname}' >> $devList
done

printf "CtrlID;EnclID;EnclSlot;SerialNbr;gptid;devname\r\n"
sort $devList

clean_tempfiles
