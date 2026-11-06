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
  # Optional. Overrides the expected audience ('aud' claim) for API bearer tokens
  # (see "Authentication with Entra ID Bearer Tokens" in the GraphQL docs). Defaults
  # to client_id and its Application ID URI form (api://YOUR_CLIENT_ID).
  # api_audience: YOUR_API_APPLICATION_ID_URI
```

To allow integrations to authenticate GraphQL API requests as the signed-in Entra ID user (instead of a shared
Personal Access Token), the app registration must expose an `access_as_user` delegated permission (scope), in
addition to any `api`/`read_api` scopes used to control query/mutation access. See
[Authentication with Entra ID Bearer Tokens](../extend/graphql.md#authentication-with-entra-id-bearer-tokens) for
details on the request/response flow, and the section below for how to configure the Entra app registration itself.

##### Setting up the Entra app registration for On-Behalf-Of API access

This section is for Entra administrators who need to allow a trusted integration (such as BDIP) to call the IRIDA
Next GraphQL API as the signed-in user via the
[On-Behalf-Of (OBO) flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow),
instead of using a shared Personal Access Token.

There are two app registrations involved:

- **IRIDA Next's app registration** — the one already used for sign-in (the `client_id`/`tenant_id` configured
  above). This is the **resource** being accessed; it must expose the API and its scopes.
- **The integration's app registration** (e.g. BDIP's) — the **client** that performs the OBO exchange on the
  user's behalf. This is a separate app registration, owned by the integration, not by IRIDA Next.

**1. Expose IRIDA Next's API and define scopes**

In the Azure/Entra portal, open IRIDA Next's app registration and go to **Expose an API**:

1. If no **Application ID URI** is set, click **Set** and accept the default (`api://<client-id>`) or set a custom
   URI. If you choose a custom URI that does not match `api://<client-id>`, set the `api_audience` credential
   shown above to match it.
2. Click **Add a scope** and add the following scopes (each needs a scope name, who can consent, and admin/user
   consent display name and description):
   - `access_as_user` — required on every bearer token; represents "act as the signed-in user". Without this
     scope, IRIDA Next rejects the token entirely.
   - `api` — grants read and write access to the GraphQL API (equivalent to the `api` Personal Access Token
     scope).
   - `read_api` — grants read-only access to the GraphQL API (equivalent to the `read_api` Personal Access Token
     scope).

**2. Authorize the integration's client application**

Still under **Expose an API**, in the **Authorized client applications** section, click **Add a client
application** and add the integration's **Application (client) ID** (e.g. BDIP's, not IRIDA Next's). Select the
`access_as_user` scope, plus `api` and/or `read_api` depending on what the integration should be allowed to do.

Pre-authorizing the client this way lets the OBO exchange succeed without an interactive admin/user consent
prompt. Alternatively, the integration's own app registration can request these as **delegated API permissions**
against IRIDA Next's app registration (under **API permissions > Add a permission > My APIs**), with an Entra
administrator granting admin consent for the tenant — either approach is sufficient, pre-authorization is simply
the more common pattern for service-to-service integrations.

**3. Confirm the integration is set up as a confidential client**

The OBO flow requires the integration to authenticate itself with a client secret or certificate when exchanging
the user's token, in addition to presenting the user's original token. This is configured on the integration's
own app registration/backend, not on IRIDA Next's.

**4. Repeat for additional integrations**

Because the audience (`aud` claim) on an OBO token always identifies IRIDA Next (the resource), not the calling
client, any number of separate integrations can be authorized this way against the same IRIDA Next app
registration: simply repeat step 2 for each integration's client ID. No changes are needed to IRIDA Next's
`client_id`/`tenant_id`/`api_audience` credentials to support additional integrations.

**5. Validate**

Once configured, the integration acquires an access token via the OBO flow requesting
`api://<IRIDA-NEXT-CLIENT-ID>/access_as_user` (plus `api` and/or `read_api`), and presents it to IRIDA Next as
described in [Authentication with Entra ID Bearer Tokens](../extend/graphql.md#authentication-with-entra-id-bearer-tokens).
The user performing the action must already have signed in to IRIDA Next at least once via the `entra_id`
provider, since IRIDA Next looks up the local account by the token's `oid`/`tid` claims rather than creating one.

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
