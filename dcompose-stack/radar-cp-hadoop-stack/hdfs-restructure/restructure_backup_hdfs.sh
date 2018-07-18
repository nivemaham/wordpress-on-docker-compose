#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"

# log file
logfile=hdfs_output.log

# landing folder. Specify if not
storage_directory=output

# lock file
lockfile=.LOCKFILE

# involved HDFS directory
hdfs_directory=/topicAndroidNew

. ./util.sh

# extract file from hdfs to backup storage if no other instance is running
if [ ! -f $lockfile ]; then
  log_info "Creating lock ..."
  touch $lockfile
  (./hdfs_restructure.sh $hdfs_directory $storage_directory >> $logfile 2>&1)
  log_info "Removing lock ..."
  rm $lockfile
else
  log_info "Another instance is already running ... "
fi
log_info "### DONE ###"

# check if log size exceeds the limit. If so, it rotates the log file
rolloverLog