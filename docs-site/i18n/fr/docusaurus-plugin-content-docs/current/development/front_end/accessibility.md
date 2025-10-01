---
id: accessibility
sidebar_position: 1
---

# Accessibilité

L'accessibilité est importante pour les utilisateurs qui utilisent des lecteurs d'écran ou qui s'appuient sur des fonctionnalités clavier uniquement pour s'assurer qu'ils ont une expérience équivalente aux utilisateurs voyants utilisant une souris.

## Essais

Nous utilisons [axe-core](https://github.com/dequelabs/axe-core) pour les tests d'accessibilité dans nos cas de test système. Vous pouvez appeler `assert_accessible` à tout moment, ce qui exécutera `axe-core` et signalera toute erreur d'accessibilité trouvée. Note : Ceci est automatiquement appelé lorsque les helpers `fill_in` ou `visit` sont appelés dans les tests.
