#!/bin/bash

if [[ $# -lt 1 || $1 = "-h" || $1 = "--help" ]]; then
   printf "Usage:\n$0 <hdfs path> [<destination directory>]\nThe destination directory defaults to ./output\n"
   exit 1
fi

. ./util.sh

# HDFS restructure version
DOCKER_IMAGE=radarbase/radar-hdfs-restructure:0.4.0

# HDFS filename to get
HDFS_FILE=$1
# Absolute directory to write output to
OUTPUT_DIR=${2:-output}
OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_DIR")"; pwd)/$(basename "$OUTPUT_DIR")"
# Internal docker directory to write output to
HDFS_OUTPUT_DIR=/output
# HDFS command to run
HDFS_COMMAND=(--compression gzip --deduplicate -u hdfs://hdfs-namenode:8020 -o "$HDFS_OUTPUT_DIR" "$HDFS_FILE" )

mkdir -p $OUTPUT_DIR
sudo-linux docker run -t --rm --network hadoop -v "$OUTPUT_DIR:$HDFS_OUTPUT_DIR" $DOCKER_IMAGE "${HDFS_COMMAND[@]}"