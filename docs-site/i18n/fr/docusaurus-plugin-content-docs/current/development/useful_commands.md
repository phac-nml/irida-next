---
sidebar_position: 3
id: useful_commands
title: Commandes utiles pour le développement
---

### Pathogen View Components en local (dépôt voisin)

Pour travailler contre un clone local `../pathogen-view-components` plutôt que le tag du Gemfile :

```bash
export USE_LOCAL_PATHOGEN=1
bundle install
```

Ou pointer Bundler vers un autre clone :

```bash
export PATHOGEN_VIEW_COMPONENTS_PATH=/chemin/absolu/vers/pathogen-view-components
bundle install
```

Avant de committer, retirez ces variables d’environnement et relancez `bundle install` pour que `Gemfile.lock` reste sur le tag publié. Ne committez pas les changements de lockfile issus du mode chemin local.

Ouvrez les deux dépôts dans Cursor avec `irida-pathogen.code-workspace` (multi-root) pour avoir la documentation Lookbook et le code de la gem à côté de l’application hôte.

### Supprimer, reconstruire et peupler la base de données

```bash
bin/rails db:drop db:create db:migrate db:seed
```

### Créer de nouvelles informations d’identification

```bash
rm config/credentials.yml.enc
EDITOR="vim --nofork" bin/rails credentials:edit
```

### Recompiler le CSS pendant l’exécution du serveur Rails

Lorsque vous exécutez le serveur avec `bin/rails s` au lieu de `bin/dev` (par exemple, lors de l’attachement du débogueur dans VS Code), lancez le processus de compilation CSS séparément :

```bash
pnpm run dev:css
```

### Construire le schéma GraphQL

```bash
bin/rails graphql:dump_schema
```

### Construire et servir la documentation

```bash
cd docs-site
pnpm update
pnpm build
npm run serve
```

### Afficher les journaux pendant les tâches Rake

Faites précéder les tâches Rake de `info`, `debug` ou `verbose` pour définir le niveau de journalisation :

```bash
# Exemple
rake debug db:seed
```

### Formater les fichiers de traduction

```bash
i18n-tasks normalize
```
