---
sidebar_position: 1
id: code_review
title: Directives de révision de code
---

Ce guide contient des conseils et des meilleures pratiques pour effectuer une révision de code et pour faire réviser votre code.

Toutes les demandes de fusion pour IRIDA Next, qu'elles soient écrites par un membre de l'équipe IRIDA ou par un membre de la communauté élargie, doivent passer par un processus de révision de code pour garantir que le code est efficace, compréhensible, maintenable et sécurisé.

## Faire réviser, approuver et fusionner votre pull request

Avant de commencer :

- Familiarisez-vous avec les [critères d'acceptation de contribution](./pull_request_workflow#contribution-acceptance-criteria)

Dès que vous avez du code à réviser, faites **réviser** le code par un réviseur. Le réviseur peut :

- Vous donner un deuxième avis sur la solution et l'implémentation choisies.
- Aider à chercher des bogues, des problèmes de logique ou des cas limites non couverts.

Faire **fusionner** votre pull request nécessite également un mainteneur. S'il nécessite plus d'une approbation, le dernier mainteneur à réviser et approuver le fusionne.

### Liste de vérification d'acceptation

Cette liste de vérification encourage les auteurs, les réviseurs et les mainteneurs des pull requests (PR) à confirmer que les changements ont été analysés pour les risques à fort impact sur la qualité, les performances, la fiabilité, la sécurité, l'observabilité et la maintenabilité.

L'utilisation de listes de vérification améliore la qualité en génie logiciel. Cette liste de vérification est un outil simple pour soutenir et renforcer les compétences des contributeurs à la base de code d'IRIDA Next.

#### Qualité

1. Vous avez effectué une auto-révision de cette PR selon les [directives de révision de code](./code_review).
1. Pour le code que ce changement impacte, vous croyez que les essais automatisés valident les fonctionnalités qui sont très importantes pour les utilisateurs.
1. Si les essais automatisés existants ne couvrent pas la fonctionnalité ci-dessus, vous avez ajouté les essais nécessaires ou ajouté un problème pour décrire l'écart d'essai d'automatisation et l'avez lié à cette PR.
1. Vous avez considéré les aspects techniques de l'impact de ce changement sur IRIDA Next.
1. Vous avez considéré l'impact de ce changement sur le frontend, le backend et les portions de base de données du système le cas échéant et avez appliqué les étiquettes `~ux`, `~frontend`, `~backend` et `~database` en conséquence.

#### Performance, fiabilité et disponibilité

1. Vous êtes confiant que cette PR ne nuit pas aux performances, ou vous avez demandé à un réviseur d'aider à évaluer l'impact sur les performances.
1. Vous avez ajouté des informations pour les réviseurs de base de données dans la description de la PR, ou vous avez décidé que c'était inutile.
1. Vous avez considéré le risque de scalabilité basé sur la croissance future prévue.

#### Documentation

1. Vous avez ajouté/mis à jour la documentation ou décidé que les changements de documentation ne sont pas nécessaires pour cette PR.

#### Sécurité

1. Vous avez confirmé que si cette PR contient un changement au traitement ou au stockage d'informations d'identification ou de jetons, aux méthodes d'autorisation et d'authentification, vous avez ajouté l'étiquette `~security`.

## Meilleures pratiques

### Tout le monde

- Soyez gentil.
- Acceptez que de nombreuses décisions de programmation sont des opinions. Discutez des compromis, celui que vous préférez, et parvenez rapidement à une résolution.
- Posez des questions ; ne faites pas de demandes. (« Que penses-tu de nommer ceci `:sample_id` ? »)
- Demandez des éclaircissements. (« Je n'ai pas compris. Peux-tu clarifier ? »)
- Évitez la propriété sélective du code. (« le mien », « pas le mien », « le tien »)
- Évitez d'utiliser des termes qui pourraient être perçus comme faisant référence à des traits personnels. (« stupide », « idiot »). Supposez que tout le monde est intelligent et bien intentionné.
- Soyez explicite. Rappelez-vous que les gens ne comprennent pas toujours vos intentions en ligne.
- Soyez humble. (« Je ne suis pas sûr - vérifions. »)
- N'utilisez pas d'hyperbole. (« toujours », « jamais », « sans fin », « rien »)
- Soyez prudent avec l'utilisation du sarcasme. Tout ce que nous faisons est public ; ce qui semble être une taquinerie de bonne nature pour vous et un collègue de longue date pourrait sembler méchant et non accueillant pour une personne nouvelle au projet.
- Envisagez des discussions individuelles ou des appels vidéo s'il y a trop de commentaires « Je n'ai pas compris » ou « Solution alternative : ». Publiez un commentaire de suivi résumant la discussion individuelle.
- Si vous posez une question à une personne spécifique, commencez toujours le commentaire en la mentionnant.

### Faire réviser votre pull request

Veuillez garder à l'esprit que la révision de code est un processus qui peut prendre plusieurs itérations, et les réviseurs peuvent repérer des choses plus tard qu'ils n'ont peut-être pas vues la première fois.

- Le premier réviseur de votre code, c'est _vous_. Avant d'effectuer cette première poussée de votre nouvelle branche brillante, lisez l'intégralité du diff. Est-ce que cela a du sens ? Avez-vous inclus quelque chose de non lié à l'objectif global des changements ? Avez-vous oublié de supprimer du code de débogage ?
- Rédigez une description détaillée comme indiqué dans les [directives de pull request](./pull_request_workflow). Certains réviseurs peuvent ne pas être familiers avec la fonctionnalité ou la zone de la base de code. Des descriptions approfondies aident tous les réviseurs à comprendre votre demande et à tester efficacement.
- Si vous savez que votre changement dépend d'une autre fusion en premier, notez-le dans la description et définissez une dépendance.
- Soyez reconnaissant pour les suggestions du réviseur. (« Bon point. Je vais faire ce changement. »)
- Ne le prenez pas personnellement. La révision porte sur le code, pas sur vous.
- Expliquez pourquoi le code existe. (« C'est comme ça à cause de ces raisons. Serait-il plus clair si je renomme cette classe/fichier/méthode/variable ? »)
- Extrayez les changements non liés et les refactorisations dans de futures demandes de fusion/problèmes.
- Cherchez à comprendre la perspective du réviseur.
- Essayez de répondre à chaque commentaire.
- L'auteur de la demande de fusion ne résout que les fils qu'il a entièrement traités. S'il y a une réponse ouverte, un fil ouvert, une suggestion, une question ou quoi que ce soit d'autre, le fil doit être laissé pour être résolu par le réviseur.
- Il ne faut pas supposer que tous les commentaires nécessitent que leurs changements recommandés soient incorporés dans la PR avant qu'elle ne soit fusionnée. C'est un jugement de l'auteur de la PR et du réviseur pour savoir si cela est nécessaire, ou si un problème de suivi devrait être créé pour traiter les commentaires à l'avenir après la fusion de la PR en question.
- Poussez les commits basés sur des tours de commentaires antérieurs comme des commits isolés vers la branche. Ne squashez pas jusqu'à ce que la branche soit prête à fusionner. Les réviseurs doivent pouvoir lire les mises à jour individuelles basées sur leurs commentaires antérieurs.
- Demandez une nouvelle révision au réviseur une fois que vous êtes prêt pour un autre tour de révision.

### Demander une révision

Lorsque vous êtes prêt à faire réviser votre pull request, vous devez demander une révision initiale en sélectionnant un réviseur basé sur les directives d'approbation.

Lorsqu'une pull request a plusieurs domaines à réviser, il est recommandé de spécifier quel domaine un réviseur devrait réviser, et à quel stade (premier ou deuxième). Cela aidera les membres de l'équipe qui sont qualifiés comme réviseurs pour plusieurs domaines à savoir quel domaine ils sont invités à réviser. Par exemple, une pull request a des préoccupations à la fois `backend` et `frontend`, vous pouvez mentionner la révision de cette manière : `@john_doe peux-tu s'il te plaît réviser ~backend` ou `@jane_doe pourrais-tu s'il te plaît donner à cette PR une révision ~frontend ?`

Vous pouvez également utiliser l'étiquette `ready for review`. Cela signifie que votre pull request est prête à être révisée et que n'importe quel réviseur peut la prendre. Il est recommandé de n'utiliser cette étiquette que s'il n'y a pas de pression temporelle et de s'assurer que la pull request est assignée à un réviseur.

Il est de la responsabilité de l'auteur de la demande de fusion d'être révisée. Si elle reste dans l'état `ready for review` trop longtemps, il est recommandé de demander une révision à un réviseur spécifique.

### Se porter volontaire pour réviser

Les ingénieurs d'IRIDA Next qui ont la capacité peuvent régulièrement vérifier la liste des [pull requests à réviser](https://github.com/phac-nml/irida-next/pulls?q=is%3Apr+is%3Aopen+label%3A%22ready+for+review%22+) et s'ajouter comme réviseur pour toute pull request qu'ils souhaitent réviser.

### Réviser une pull request

Comprenez pourquoi le changement est nécessaire (corrige un bogue, améliore l'expérience utilisateur, refactorise le code existant). Ensuite :

- Essayez d'être minutieux dans vos révisions pour réduire le nombre d'itérations.
- Communiquez les idées pour lesquelles vous avez des convictions fortes et celles pour lesquelles vous n'en avez pas.
- Identifiez des moyens de simplifier le code tout en résolvant le problème.
- Offrez des implémentations alternatives, mais supposez que l'auteur les a déjà envisagées. (« Que penses-tu d'utiliser un validateur personnalisé ici ? »)
- Cherchez à comprendre la perspective de l'auteur.
- Récupérez la branche et testez les changements localement. Vous pouvez décider de l'étendue des essais manuels que vous souhaitez effectuer. Vos essais pourraient entraîner des opportunités d'ajouter des essais automatisés.
- Si vous ne comprenez pas un morceau de code, _dites-le_. Il y a de bonnes chances que quelqu'un d'autre soit également confus.
- Assurez-vous que l'auteur comprend clairement ce qui est requis de sa part pour traiter/résoudre la suggestion.
  - Envisagez d'utiliser le [format Conventional Comment](https://conventionalcomments.org/#format) pour transmettre votre intention.
  - Pour les suggestions non obligatoires, décorez avec (non-bloquant) afin que l'auteur sache qu'il peut éventuellement résoudre dans la pull request ou faire un suivi ultérieurement.
  - Il existe un [module complémentaire Chrome](https://chrome.google.com/webstore/detail/conventional-comments/pagggmojbbphjnpcjeeniigdkglamffk) et [Firefox](https://addons.mozilla.org/en-US/firefox/addon/conventional-comments/) que vous pouvez utiliser pour appliquer les préfixes [Conventional Comment](https://conventionalcomments.org).
- Assurez-vous qu'il n'y a pas de dépendances ouvertes.
- Après un tour de notes de ligne, il peut être utile de publier une note récapitulative telle que « Ça me semble bon » ou « Juste quelques choses à traiter ».
- Faites savoir à l'auteur si des changements sont requis suite à votre révision.

### Fusionner une pull request

Avant de prendre la décision de fusionner :

- Confirmez que l'étiquette de type de PR correcte est appliquée.
- Tenez compte des avertissements et des erreurs des rapports de qualité du code et autres. À moins qu'un argument solide puisse être avancé pour la violation, ceux-ci doivent être résolus avant la fusion. Un commentaire doit être publié si la PR est fusionnée avec un travail échoué.

Au moins un mainteneur doit approuver une PR avant qu'elle puisse être fusionnée. Les auteurs de PR et les personnes qui ajoutent des commits à une PR ne sont pas autorisés à approuver ou fusionner la PR et doivent rechercher un mainteneur qui n'a pas contribué à la PR pour l'approuver et la fusionner.

Lorsque prêt à fusionner :

- Envisagez d'utiliser la fonctionnalité Squash and merge lorsque la pull request a beaucoup de commits. Lors de la fusion du code, un mainteneur ne devrait utiliser la fonctionnalité de squash que si l'auteur a déjà défini cette option, ou si la demande de fusion contient clairement un historique de commits désordonné, il sera plus efficace de squasher les commits au lieu de revenir vers l'auteur à ce sujet. Sinon, si la PR n'a que quelques commits, nous respecterons le paramètre de l'auteur en ne les squashant pas.

## Crédits

Largement basé sur le [guide de révision de code de `gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/code_review.md), qui était largement basé sur le [guide de révision de code de `thoughtbot`](https://github.com/thoughtbot/guides/tree/master/code-review).
