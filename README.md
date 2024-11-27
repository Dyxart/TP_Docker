# Documentation du Projet : Mise en place d'un Environnement Docker pour GLPI

## Introduction
Ce projet vise à déployer une solution basée sur **GLPI** dans un environnement Docker. Les services déployés incluent :
- **GLPI** pour la gestion des ressources.
- Une base de données **MariaDB**.
- Un serveur proxy **Nginx** pour gérer les requêtes HTTP.

## Architecture
L'architecture repose sur trois conteneurs Docker interconnectés :
- **GLPI** : Application principale.
- **MariaDB** : Base de données pour stocker les informations.
- **Nginx** : Serveur proxy qui redirige les requêtes HTTP vers le conteneur GLPI.

## Réseau
Deux réseaux Docker sont configurés :
- **`public_network`** : Permet la communication entre Nginx et l'extérieur.
- **`private_network`** : Sécurise les échanges entre GLPI et MariaDB, isolant la base de données du public.

## Fichiers et Configurations

### Fichier `docker-compose.yml`
Le fichier `docker-compose.yml` décrit les services et leurs configurations. 

#### Contenu
```yaml
version: '9999'

services:
  glpi:
    image: diouxx/glpi:latest
    container_name: glpi
    restart: unless-stopped
    networks:
      - public_network
      - private_network
    environment:
      GLPI_DB_HOST: db
      GLPI_DB_NAME: glpidb
      GLPI_DB_USER: glpiuser
      GLPI_DB_PASSWORD: glpipassword
    depends_on:
      - db
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: mariadb:latest
    container_name: glpi_db
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: glpidb
      MYSQL_USER: glpiuser
      MYSQL_PASSWORD: glpipassword
    networks:
      - private_network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 10s
      interval: 10s
      timeout: 5s
      retries: 3

  nginx:
    image: nginx:latest
    container_name: glpi_nginx
    restart: unless-stopped
    ports:
      - "8081:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - public_network
    depends_on:
      - glpi
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  db_data:

networks:
  public_network:
    driver: bridge
  private_network:
    driver: bridge
```

### Fichier `nginx.conf`
Le fichier `nginx.conf` configure le serveur proxy Nginx pour rediriger les requêtes HTTP vers GLPI.

#### Contenu
```nginx
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    server {
        listen 80;

        server_name glpi.local;

        location / {
            proxy_pass http://glpi:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

---

## Sauvegarde Automatique des Volumes Docker

Pour garantir la pérennité des données, une tâche Cron a été configurée pour sauvegarder automatiquement le volume Docker `db_data`.

### Script de sauvegarde (`backup.sh`)
```bash
#!/bin/bash

VOLUMES=("db_data")
BACKUP_DIR="/path/to/backups"
DATE=$(date +"%Y%m%d%H%M")
mkdir -p $BACKUP_DIR

for VOLUME in "${VOLUMES[@]}"; do
  docker run --rm \
    -v ${VOLUME}:/volume \
    -v ${BACKUP_DIR}:/backup \
    alpine tar czf /backup/${VOLUME}_${DATE}.tar.gz /volume
done
```

### Configuration Cron
Ajoutez cette tâche dans le fichier Crontab :
```bash
0 2 * * * /path/to/backup.sh
```

---

## Scripts pour la Gestion des Images Docker

### Script de Déploiement des Images Docker à Jour

Ce script permet de mettre à jour les conteneurs en utilisant les dernières versions des images Docker disponibles.

**Nom du script :** `deploy-images.sh`
```bash
#!/bin/bash

echo "Arrêt des conteneurs existants..."
docker compose down

echo "Mise à jour des images Docker..."
docker compose pull

echo "Relance des conteneurs avec les images mises à jour..."
docker compose up -d

echo "État des conteneurs après mise à jour :"
docker ps
```

### Script pour Restaurer une Sauvegarde

Ce script restaure les données d'un volume Docker à partir d'une sauvegarde existante.

**Nom du script :** `restore.sh`
```bash
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
docker run --rm \
  -v $VOLUME_NAME:/volume \
  -v $(dirname $BACKUP_FILE):/backup \
  alpine tar xzf /backup/$(basename $BACKUP_FILE) -C /volume

echo "Relance des conteneurs..."
docker compose up -d
```

---

## Tests et Validation

1. **Validation des Healthchecks**
   - Vérifiez les statuts des conteneurs avec :
     ```bash
     docker ps
     ```

2. **Test des scripts**
   - **Script de déploiement** : Lancez `deploy-images.sh` pour mettre à jour les conteneurs.
   - **Script de restauration** : Assurez-vous qu'une sauvegarde valide est disponible, puis lancez `restore.sh`.

---

## Points d'Amélioration
- Intégrer les scripts dans un pipeline CI/CD pour automatiser les mises à jour.
- Ajouter des tests automatisés pour valider les sauvegardes après restauration.

---

## Conclusion
Cette documentation rassemble tous les éléments nécessaires pour gérer et maintenir votre environnement Docker pour GLPI, avec une surveillance active, des sauvegardes, et des mises à jour simplifiées.
