#!/bin/bash

echo "Arrêt des conteneurs existants..."
docker compose down

echo "Mise à jour des images Docker..."
docker compose pull

echo "Relance des conteneurs avec les images mises à jour..."
docker compose up -d

echo "État des conteneurs après mise à jour :"
docker ps
