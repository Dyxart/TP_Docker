#!/bin/bash

VOLUMES=("db_data")
BACKUP_DIR="/path/to/backups"
DATE=$(date +"%Y%m%d%H%M")
mkdir -p $BACKUP_DIR

for VOLUME in "${VOLUMES[@]}"; do
  docker run --rm     -v ${VOLUME}:/volume     -v ${BACKUP_DIR}:/backup     alpine tar czf /backup/${VOLUME}_${DATE}.tar.gz /volume
done
