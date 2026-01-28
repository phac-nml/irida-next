---
sidebar_position: 7
id: integration_auth
title: Connecter les intégrations à l'authentification IRIDA Next
---

## Configuration IRIDA Next

### Fichier de configuration

Le fichier de configuration se trouve à : `config/integrations/cors_config.yml`

#### Exemple de configuration

```yaml
development:
  # origins 'localhost:3000', '127.0.0.1:3000',
  #            /\Ahttp:\/\/192\.168\.0\.\d{1,3}(:\d+)?\z/
  # Les expressions régulières sont autorisées.
  origins: "*"
  resources:
    - resource: "*"
      headers: any
      methods: [get, post]
  # Assurez-vous d'inclure le '/' à la fin
  allowed_hosts:
    - url: "http://localhost:8081/"
      identifier: bdip_sheets
      token_lifespan_days: 2
```

Pour un environnement de production, placez toutes les options de configuration sous le titre `production:`

#### Configuration CORS

Les sections `origins:` et `resources:` sont utilisées pour la configuration CORS.

Cross-Origin Resource Sharing (CORS) est un mécanisme de sécurité. Familiarisez-vous avec les bonnes pratiques et trouvez la portée la plus restreinte à ajouter à votre configuration.

https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS

#### Configuration de l'intégration

La section `allowed_hosts:` est utilisée par IRIDA Next pour associer les jetons aux intégrations, déterminer la durée de validité du jeton et vérifier que l'origine de la demande correspond aux identifiants associés.

`url:`

Chaque intégration doit utiliser une URL unique pour recevoir les demandes d'authentification. Cette URL doit être statique et spécifique. L'URL est déterminée par la page à partir de laquelle la demande de jeton d'intégration est générée.

`identifier:`

Une chaîne d'identifiant unique contenant uniquement des caractères, des chiffres et `-` ou `_`. Cela devrait être lisible par l'homme, par exemple `bdip_sheets`

`token_lifespan_days:`

Nombre de jours pendant lesquels un jeton restera actif avant sa suppression automatique.

## Configuration du code d'intégration

Un service intégré peut ouvrir une fenêtre ciblant le point de terminaison `/integration_access_token` d'IRIDA Next, qui s'attend à un argument `caller`.

Exemple : `https://my.iridanext.site/integration_access_token?caller=my_integration`

### Méthodes

L'ouverture de la fenêtre vers le dialogue d'intégration à l'aide de javascript ressemble à ceci

```javascript
window.open(URL, "access-token-popup", options);
```

Et la réception du jeton de la fenêtre d'authentification d'intégration doit être effectuée avec un écouteur d'événement comme celui-ci

```javascript
window.addEventListener("message", (event) => {
  if (event.origin !== ORIGIN) return; // vérification basique de l'origine
  console.log("Jeton reçu :", event.data);
});
```

Un script plus complet devrait ressembler à ceci

```javascript
// Ouvre la fenêtre contextuelle de jeton d'accès d'intégration et consigne le jeton retourné.
const ORIGIN = "http://localhost:3000";
const URL = ORIGIN + "/integration_access_token?caller=bdip_sheets";

document.getElementById("inxt-btn").addEventListener("click", () => {
  var x = window.screenX || window.screenLeft || 0;
  var y = window.screenY || window.screenTop || 0;
  const options = `width=500,height=800,top=${y},left=${x}`;
  const popup = window.open(URL, "access-token-popup", options);
  if (!popup) console.warn("Fenêtre contextuelle bloquée");
});

window.addEventListener("message", (event) => {
  if (event.origin !== ORIGIN) return; // vérification basique de l'origine
  console.log("Jeton reçu :", event.data);
});
```

### Exemple complet

Une démo entièrement fonctionnelle préconfigurée pour fonctionner avec la configuration `development:` par défaut dans la base de code peut être trouvée à : `demos/access-token-integration-demo/index.html`
