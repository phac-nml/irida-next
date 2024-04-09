---
sidebar_position: 2
id: mail
title: Configuring mail options
---

## Setup

The following options can be set in the rails credentials file.

```yml
action_mailer:
  default_from: <some email address>
  smtp_options:
    address: <some smtp server>
    port: <some smtp port>
    ...
```

### default_from

The default from email address in all mail sent from the application.

### smtp_options

Can be used to connect to a specific smtp server to use to send the emails.

See https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration
