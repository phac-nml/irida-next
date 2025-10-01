---
sidebar_position: 1
id: ga4gh_wes_sapporo_setup
title: Configuration de GA4GH WES Sapporo
---

## Prérequis

Vous devrez avoir le [plugin Docker Compose](https://docs.docker.com/compose/install/linux/) installé pour gérer Sapporo

```bash
# Instructions pour installer le plugin Docker Compose sur Ubuntu
sudo apt-get update
sudo apt-get install docker-compose-plugin
# Vérifier l'installation
docker compose version
# résultat attendu
> Docker Compose version vN.N.N
# Vous devriez avoir la version v2.26.1 ou plus récente
```

Vous devrez vous ajouter au groupe docker pour pouvoir exécuter les commandes docker

```bash
# créer le groupe docker s'il n'existe pas
sudo groupadd docker
# vous ajouter au groupe docker
sudo usermod -aG docker $USER
# redémarrer, se déconnecter/se connecter, ou exécuter la commande suivante
newgrp docker
# Si vous avez toujours des problèmes pour exécuter docker, vous devrez peut-être modifier les permissions du socket docker en utilisant la commande suivante
sudo chmod 666 /var/run/docker.sock
```

## Comment configurer une instance Sapporo GA4GH WES pour le développement

Note : Ceci ne devrait être utilisé qu'à des fins de développement, utilisez un serveur WSGI de production pour les environnements de production.

### Configurer IRIDA Next

Vérifiez que votre service de stockage actif est défini sur `:local` dans `config/environments/development.rb`. C'est la configuration par défaut.

```ruby
config.active_storage.service = :local
```

Configurer les informations d'identification de l'environnement de développement

```bash
EDITOR="vim --nofork" bin/rails credentials:edit --environment development
```

```yml
ga4gh_wes:
  server_url_endpoint: 'http://localhost:1122/'
```

### Configuration de Sapporo (implémentation WES)

Téléchargez et exécutez le fork [PHAC-NML Sapporo](https://github.com/phac-nml/sapporo-service) en mode docker de développement.

Note : Si vos permissions de groupe docker sont configurées correctement, vous ne devriez pas avoir à utiliser `sudo` lors de l'exécution de ces commandes.

```bash
# Allez où vous stockez vos dépôts git
cd ~/path/to/git/repos
# Cloner et extraire la branche irida-next
git clone git@github.com:phac-nml/sapporo-service.git
cd sapporo-service
# Cette branche a un script docker compose personnalisé pour irida next
git checkout irida-next
# Remplacez /PATH/TO/IRIDA/NEXT/REPO par votre chemin de dépôt irida next.
# Cela permet au conteneur docker un accès en lecture/écriture au dépôt
# Ceci est nécessaire pour qu'il puisse lire les fichiers d'entrée et écrire les fichiers de sortie dans les répertoires blob
IRIDA_NEXT_PATH=/PATH/TO/IRIDA/NEXT/REPO docker compose -f compose.irida-next.yml up -d --build
IRIDA_NEXT_PATH=/PATH/TO/IRIDA/NEXT/REPO docker compose -f compose.irida-next.yml exec app bash
# Dans le conteneur docker, démarrer sapporo
sapporo
```

Dans un nouveau terminal, confirmez que sapporo fonctionne

```bash
# Cela devrait afficher toutes les informations de service pour cette instance ga4gh wes
curl -X GET http://localhost:1122/service-info
```

Vous devriez maintenant pouvoir démarrer IRIDA Next et exécuter des flux de travail avec une intégration complète de GA4GH WES
