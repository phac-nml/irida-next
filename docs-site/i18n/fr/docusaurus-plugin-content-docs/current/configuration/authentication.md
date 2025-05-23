---
sidebar_position: 1
id: authentication
title: Connecting to an Authentication Server
---

## Setup

### Enable remote authentication

By default, remote authentication is disabled. To enable it you will need to edit the config file `config/authentication/auth_config.yml`

The auth_config.yml has the format below.

```yml
development:
  omniauth_providers: [developer]
  # developer_text:
  # developer_icon:
  # saml_text:
  # saml_icon:
  # entra_id_text:
  # entra_id_icon:

test:
  omniauth_providers: [developer, saml, entra_id]
  # developer_text:
  # developer_icon:
  # saml_text:
  # saml_icon:
  # entra_id_text:
  # entra_id_icon:

# production:
  # omniauth_providers: []
  # saml_text:
  # saml_icon:
  # entra_id_text:
  # entra_id_icon:
```

For your production environment, uncomment and edit the relevant `production` lines.

For Entra ID, formerly Azure Active Directory

```yml
production:
  omniauth_providers: [entra_id]
```

For SAML

```yml
production:
  omniauth_providers: [saml]
```

### Credentials

You will need to setup the authentication server credentials in the IRIDA Next secret credentials file.

You can edit this file with the following command.

```bash
EDITOR="vim --nofork" bin/rails credentials:edit
```

#### Entra ID (formerly Azure Active Directory V2)

For Entra, you will need the following lines

```yml
entra_id:
  client_id: YOUR_CLIENT_ID
  client_secret: YOUR_CLIENT_SECRET
  tenant_id: YOUR_TENANT_ID
```

#### SAML

For SAML, you will need the following lines

```yml
saml:
  idp_sso_service_url: YOUR_SAML_IDP_SSO_SERVICE_URL
  sp_entity_id: YOUR_SAML_SP_ENTITY_ID
  idp_cert: YOUR_SAML_IDP_CERT
```

## Further customization

You can change the display name and icon to match your organization.

In the `config/authentication/auth_config.yml` file, edit `_text` and `_icon` fields appropriate for your Entra or SAML setup.

Put your organizations name in the `_text` field.

Place a `.svg` icon file in the `config/authentication/icons/` directory and add the filename to the `_icon` field.

Example:

```yml
production:
  omniauth_providers: [entra_id]
  # saml_text:
  # saml_icon:
  entra_id_text: Tyrell Corporation
  entra_id_icon: tyrell.svg
```
