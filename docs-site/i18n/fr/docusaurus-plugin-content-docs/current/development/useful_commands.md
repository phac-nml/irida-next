---
sidebar_position: 3
id: useful_commands
title: Commandes utiles pour le développement
---

### Supprimer, reconstruire et peupler la bd

``` bash
bin/rails db:drop db:create db:migrate db:seed
```

### Créer de nouvelles informations d'identification

``` bash
rm config/credentials.yml.enc
EDITOR="vim --nofork" bin/rails credentials:edit
```

### Processus additionnel pour que les changements d'interface utilisateur soient mis à jour au fur et à mesure qu'ils sont modifiés

Lors de l'exécution du serveur avec `bin/rails s` au lieu de `bin/dev`, comme lors de l'attachement du débogueur dans VSCode, le processus tailwind peut être exécuté séparément.

``` bash
bin/rails tailwindcss:watch
```

### Construire le schéma graphql

``` bash
bin/rails graphql:dump_schema
```

### Construire et exécuter la documentation

```bash
cd docs-site
pnpm update
pnpm build
npm run serve
```

### Sortir les journaux pendant les tâches rake

Les tâches rake peuvent être précédées de `info`, `debug` ou `verbose` pour sortir le niveau de journalisation approprié

```bash
# Exemple
rake debug db:seed
```
