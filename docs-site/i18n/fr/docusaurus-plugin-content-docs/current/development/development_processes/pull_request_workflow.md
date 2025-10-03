---
sidebar_position: 2
id: pull_request_workflow
title: Flux de travail des pull requests
---

Nous accueillons les pull requests de tous, avec des corrections et des améliorations au code, aux essais et à la documentation d'IRIDA Next.

## Directives de demande de fusion pour les contributeurs

### Meilleures pratiques

- Si le changement n'est pas trivial, nous vous encourageons à entamer une discussion avec un membre de l'équipe. Vous pouvez le faire en les identifiant dans une PR avant de soumettre le code pour révision. Parler aux membres de l'équipe peut être utile lors de la prise de décisions de conception. Communiquer l'intention derrière vos changements peut également aider à accélérer les révisions de pull request.
- Lorsque vous faites réviser votre code et lorsque vous révisez des pull requests, veuillez garder à l'esprit les [directives de révision de code](./code_review).

### Rester simple

Vivez selon _des itérations plus petites_. Veuillez garder la quantité de changements dans une seule PR **aussi petite que possible**. Si vous souhaitez contribuer une grande fonctionnalité, réfléchissez très attentivement à ce qu'est le changement minimum viable. Pouvez-vous diviser la fonctionnalité en deux PR plus petites ? Pouvez-vous soumettre uniquement le code backend/API ? Pouvez-vous commencer avec une interface utilisateur très simple ? Pouvez-vous faire juste une partie de la refonte ?

Les petites PR qui sont plus facilement révisées conduisent à une qualité de code plus élevée, ce qui est plus important pour IRIDA Next qu'avoir un journal de commits minimal. Plus une PR est petite, plus elle sera probablement fusionnée rapidement. Après cela, vous pouvez envoyer plus de PR pour améliorer et étendre la fonctionnalité. Le document [Comment obtenir des révisions de PR plus rapides](https://github.com/kubernetes/kubernetes/blob/release-1.5/docs/devel/faster_reviews.md) de l'équipe Kubernetes a également d'excellents points à ce sujet.

## Critères d'acceptation de contribution

Pour vous assurer que votre pull request peut être approuvée, veuillez vous assurer qu'elle répond aux critères d'acceptation de contribution ci-dessous :

1. Le changement est aussi petit que possible.
1. Si la pull request contient plus de 500 changements :
   - Expliquez la raison
1. Mentionnez tout changement majeur cassant.
1. Incluez des essais appropriés et assurez-vous que tous les essais réussissent (sauf si elle contient un essai exposant un bogue dans le code existant). Chaque nouvelle classe devrait avoir des essais unitaires correspondants, même si la classe est exercée à un niveau supérieur, comme un essai de fonctionnalité.
   - Si une construction CI échouée semble sans rapport avec votre contribution, vous pouvez essayer de redémarrer le travail CI échoué, de rebaser sur la branche cible pour intégrer des mises à jour qui peuvent résoudre l'échec, ou si cela n'a pas encore été corrigé, demander à un développeur de vous aider à corriger l'essai.
1. La PR contient quelques commits organisés logiquement, ou a le squashing des commits activé.
1. Les changements peuvent fusionner sans problèmes. Sinon, vous devriez rebaser si vous êtes le seul à travailler sur votre branche de fonctionnalité, sinon fusionner la branche par défaut dans la branche PR.
1. Un seul problème spécifique est corrigé ou une seule fonctionnalité spécifique est implémentée. Ne combinez pas les choses ; envoyez des pull requests séparées pour chaque problème ou fonctionnalité.
1. Les migrations ne doivent faire qu'une seule chose (par exemple, créer une table, déplacer des données vers une nouvelle table ou supprimer une ancienne table) pour faciliter la réessai en cas d'échec.
1. Contient des fonctionnalités dont d'autres utilisateurs bénéficieront.
1. N'ajoute pas d'options de configuration ou de paramètres car ils compliquent la réalisation et les essais de futurs changements.
1. Les changements ne dégradent pas les performances :
   - Évitez l'interrogation répétée de points de terminaison qui nécessitent une surcharge importante.
   - Vérifiez les requêtes N + 1 via le journal SQL.
   - Évitez l'accès répété au système de fichiers.
1. Si la pull request ajoute de nouvelles bibliothèques (comme des gems ou des bibliothèques JavaScript), elles doivent se conformer à nos directives de licence. De plus, informez le réviseur de la nouvelle bibliothèque et expliquez pourquoi vous en avez besoin.

## Définition de terminé

Si vous contribuez à IRIDA Next, sachez que les changements impliquent plus que du code. Nous utilisons la [définition de terminé](https://www.agilealliance.org/glossary/definition-of-done) suivante.

Si une régression se produit, nous préférons que vous annuliez le changement. Votre contribution est _incomplète_ jusqu'à ce que vous vous soyez assuré qu'elle répond à toutes ces exigences.

### Fonctionnalité

1. Code fonctionnel et propre qui est commenté au besoin.
1. Documenté dans le répertoire `/docs`.
1. Si votre pull request ajoute une ou plusieurs migrations, assurez-vous d'exécuter toutes les migrations sur une base de données fraîche avant que la PR ne soit révisée. Si la révision conduit à des changements importants dans la PR, exécutez à nouveau les migrations après que la révision soit terminée.
1. Si votre pull request ajoute de nouvelles validations aux modèles existants, pour vous assurer que le traitement des données est rétrocompatible :
   - Demandez l'assistance d'un membre de l'équipe IRIDA pour exécuter la requête de base de données qui vérifie les lignes existantes pour s'assurer que les lignes existantes ne sont pas impactées par le changement.

### Essais

1. Essais unitaires, d'intégration et système qui réussissent tous sur le serveur CI.
1. Les régressions et les bogues sont couverts par des essais qui réduisent le risque que le problème ne se reproduise.
1. Si votre demande de fusion ajoute une ou plusieurs migrations, écrivez des essais pour les migrations plus complexes.

### Changements d'interface utilisateur

1. Utilisez les composants disponibles du système de conception IRIDA Next, Viral.
   - Si vous ajoutez un nouveau composant, il est préférable de le soumettre en tant que PR séparée.
1. La PR doit inclure des captures d'écran _Avant_ et _Après_ si des changements d'interface utilisateur sont apportés.
1. Si la PR change des classes CSS, veuillez inclure la liste des pages affectées, qui peut être trouvée en exécutant `grep css-class ./app -R`.

### Description des changements

1. Titre et description clairs expliquant la pertinence de la contribution.
1. La description inclut toutes les étapes ou la configuration requise pour garantir que les réviseurs peuvent voir les changements que vous avez apportés.

### Approbation

1. La [liste de vérification d'acceptation de PR](./code_review#acceptance-checklist) a été cochée comme confirmée dans la PR.
1. Révisée par les réviseurs pertinents, et toutes les préoccupations sont traitées pour la disponibilité, les régressions et la sécurité. Les révisions de documentation doivent avoir lieu dès que possible, mais elles ne doivent pas bloquer une demande de fusion.
1. Votre pull request a au moins 1 approbation, mais selon vos changements, elle pourrait nécessiter des approbations supplémentaires.
   - Vous n'êtes pas obligé de sélectionner des réviseurs spécifiques, mais vous pouvez le faire si vous voulez vraiment que des personnes spécifiques approuvent votre pull request.
1. Fusionnée par un mainteneur de projet.

## Sujets connexes

- [Faire réviser votre pull request](./code_review#having-your-pull-request-reviewed)
