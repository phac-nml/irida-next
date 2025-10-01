---
id: view_component
sidebar_position: 2
---

# View Component

## Parcourir les composants avec LookBook

Nous avons un [LookBook](https://v2.lookbook.build/guide) à `http://localhost:3000/rails/lookbook` (uniquement disponible en mode développement) pour parcourir et interagir avec les aperçus ViewComponent.

## Meilleures pratiques

- Si vous créez une nouvelle vue en Html, utilisez les composants disponibles plutôt que de créer des balises Html simples avec des classes Tailwind CSS.
- Si vous apportez des modifications à une vue Html existante, par exemple, une icône svg qui est toujours implémentée en Html simple, envisagez de la migrer pour utiliser un ViewComponent.
- Si vous décidez de créer un nouveau composant, envisagez de créer également des [aperçus](https://viewcomponent.org/guide/previews.html) pour celui-ci. Cela aidera les autres à découvrir votre composant avec LookBook, et cela facilite également beaucoup les tests de ses différents états.
