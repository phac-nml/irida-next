---
id: view_component
sidebar_position: 2
---

# Composant de vue

## Pathogen View Components

Préférez les composants `Pathogen::*` de la gem voisine [pathogen-view-components](https://github.com/phac-nml/pathogen-view-components) pour toute nouvelle interface utilisateur réutilisable. Les règles de conception se trouvent dans ce dépôt sous `docs/lookbook/design_system/`.

Pour développer contre un clone local voisin de la gem, voir [Commandes utiles](../useful_commands.md#pathogen-view-components-en-local-dépôt-voisin) (`USE_LOCAL_PATHOGEN=1`). Ouvrez `irida-pathogen.code-workspace` pour un espace de travail Cursor multi-root incluant les deux dépôts.

Les composants locaux `Viral::*` sont des couches de compatibilité. Préférez Pathogen pour toute nouvelle interface partagée.

## Parcourir les composants avec Lookbook

Utilisez [Lookbook](https://v2.lookbook.build/guide) à l’adresse `http://localhost:3000/rails/lookbook` (disponible uniquement en mode développement) pour parcourir et interagir avec les aperçus ViewComponent.

## Meilleures pratiques

- Lors de la création d’une nouvelle vue HTML, utilisez les composants disponibles plutôt que des balises HTML simples avec des classes Tailwind CSS.
- Lors de la modification d’une vue HTML existante — par exemple, une icône SVG encore écrite en HTML simple — envisagez de la migrer vers un ViewComponent.
- Lors de la création d’un nouveau composant, ajoutez également des [aperçus](https://viewcomponent.org/guide/previews.html). Les aperçus rendent le composant découvrable dans Lookbook et facilitent les essais de ses différents états.
