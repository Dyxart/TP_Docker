#!/bin/bash

VOLUME_NAME="db_data"
BACKUP_FILE="/path/to/backups/db_data_YYYYMMDDHHMM.tar.gz"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Fichier de sauvegarde introuvable : $BACKUP_FILE"
  exit 1
fi

echo "Arrêt des conteneurs..."
docker compose down

echo "Suppression du volume existant : $VOLUME_NAME"
docker volume rm $VOLUME_NAME

echo "Recréation du volume : $VOLUME_NAME"
docker volume create $VOLUME_NAME

echo "Restauration de la sauvegarde : $BACKUP_FILE"
docker run --rm   -v $VOLUME_NAME:/volume   -v $(dirname $BACKUP_FILE):/backup   alpine tar xzf /backup/$(basename $BACKUP_FILE) -C /volume

echo "Relance des conteneurs..."
docker compose up -d
