---
id: view_component
sidebar_position: 2
---

# Composant de vue

## Pathogen View Components

Préférez les composants `Pathogen::*` de la gem voisine [pathogen-view-components](https://github.com/phac-nml/pathogen-view-components) pour toute nouvelle interface utilisateur réutilisable. Les règles de conception se trouvent dans ce dépôt sous `docs/lookbook/design_system/`.

Pour ce qui appartient à la gem versus l’application hôte, lisez la page Lookbook Pathogen [Host and library boundary](https://github.com/phac-nml/pathogen-view-components/blob/main/docs/lookbook/design_system/06-host-library-boundary.md.erb) (clone local : `../pathogen-view-components/docs/lookbook/design_system/06-host-library-boundary.md.erb`).

État cible pour IRIDA Next : l’UI réutilisable est uniquement Pathogen. Les composants `Viral::*` existants sont une dette héritée — remplacez les appels par `Pathogen::*` (ou promouvez le motif dans Pathogen), puis supprimez la classe Viral. N’ajoutez pas de nouveaux composants Viral.

Pour développer contre un clone local voisin de la gem, voir [Commandes utiles](../useful_commands.md#pathogen-view-components-en-local-dépôt-voisin) (`USE_LOCAL_PATHOGEN=1`). Ouvrez `irida-next-pathogen.code-workspace` dans un éditeur de code (VS Code, Cursor, etc.) pour un espace de travail multi-root incluant les deux dépôts.

## Parcourir les composants avec Lookbook

Utilisez [Lookbook](https://v2.lookbook.build/guide) à l’adresse `http://localhost:3000/rails/lookbook` (disponible uniquement en mode développement) pour parcourir et interagir avec les aperçus ViewComponent.

## Meilleures pratiques

- Lors de la création d’une nouvelle vue HTML, utilisez les composants disponibles plutôt que des balises HTML simples avec des classes Tailwind CSS.
- Lors de la modification d’une vue HTML existante — par exemple, une icône SVG encore écrite en HTML simple — envisagez de la migrer vers un ViewComponent.
- Lors de la création d’un nouveau composant, ajoutez également des [aperçus](https://viewcomponent.org/guide/previews.html). Les aperçus rendent le composant découvrable dans Lookbook et facilitent les essais de ses différents états.
