---
sidebar_position: 2
id: ga4gh_wes
title: Connecting to a GA4GH WES server
---

### Setup

The following fields can be set in the rails credentials file.

```yml
ga4gh_wes:
  oauth_token: <some oauth token>
  headers: { '<some header key>': '<some header value>' }
  server_url_endpoint: 'https://<some server url>/wes/1.01/'
```

#### oauth_token

Bearer token for OAuth 2.0

#### headers

Can be used to set new headers and override existing headers

This allows for additional authentication or server settings for your specific deployment of GA4GH WES

By default `{ 'Content-Type': 'application/json' }` is set.

#### server_url_endpoint

Can be used to set a specific server endpoint.

When this is set, make sure to include the full endpoint. e.g. `https://subdomain.domain.tld/wes/1.01/`

`TODO WIP: to be completed when integration is connected to workflow executions`
By default uses (some other url) with REST API versioning. e.g. `my_url_start_config_value/ga4gh_wes/v1/`
