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
version: '3.9'

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

  nginx:
    image: nginx:latest
    container_name: glpi_nginx
    restart: unless-stopped
    ports:
      - "8081:80" # Expose Nginx uniquement sur le port 8081
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - public_network
    depends_on:
      - glpi

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

## Étapes de Mise en Œuvre

### 1. Configuration des Réseaux
Deux réseaux Docker ont été créés :
- `public_network` : Pour connecter Nginx avec le monde extérieur.
- `private_network` : Pour isoler les communications entre GLPI et la base de données.

### 2. Déploiement de la Base de Données
Le service **MariaDB** a été configuré pour assurer la persistance des données via le volume `db_data`. Les variables d'environnement définissent les paramètres de connexion.

### 3. Déploiement de GLPI
Le conteneur **GLPI** utilise l'image Docker officielle et se connecte à la base de données via le réseau privé.

### 4. Déploiement de Nginx
Le serveur proxy Nginx redirige les requêtes entrantes vers GLPI et expose son port sur `8081`.

### Commandes Principales
Pour lancer les services :
```bash
docker-compose up -d
```

Pour vérifier l'état des conteneurs :
```bash
docker ps
```

## Tests et Validation

1. **Accès Nginx** : Tester l'accès via `http://<server_ip>:8081`.
2. **Validation des Réseaux** : Utiliser des outils comme `tcpdump` pour vérifier l'isolation du réseau privé.
3. **Persistance des Données** : S'assurer que les données de la base sont conservées après suppression du conteneur MariaDB.

## Points d'Amélioration
- Ajouter des **healthchecks** pour surveiller l'état des services.
- Mettre en place une tâche **Cron** pour sauvegarder régulièrement les volumes.
- Automatiser la mise à jour des images via un pipeline **CI/CD**.

---

## Conclusion
Cette configuration assure un environnement Docker sécurisé et performant pour déployer GLPI. Les bonnes pratiques ont été suivies pour garantir l'isolation des services et la persistance des données.
