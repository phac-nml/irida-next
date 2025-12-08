# IRIDA Next

> IRIDA Next is an open source bioinformatics platform for the storage, management, and analysis of genomic sequences and metadata.

## Contributing

[`devenv`](https://devenv.sh/) is used to provide a reproducible development environment for this project. Follow the [getting started instructions](https://devenv.sh/getting-started/) (note: I recommend going with single-user mode for nix which can be found under the `WSL2` tab, and then installing `deven` under the `Nix profiles (requires experimental flags)`).

Note: If using a linux system with ldap auth via sssd, then install the following with nix.

```bash
nix profile install nixpkgs#sssd
```

To automatically load the environment you should [install direnv](https://devenv.sh/automatic-shell-activation/) and then load the `direnv`.

```bash
# The security mechanism didn't allow to load the `.envrc`.
# Since we trust it, let's allow it execution.
direnv allow .
```

At this point you should see the `nix` commands available in your terminal.

### Startup the services

    $ devenv up

### Run the setup script (which will by default startup the application)

    $ bin/setup

Navigate in your browser to [http://localhost:3000](http://localhost:3000)

### Test

```bash
bin/rails test:all
```

### Running tests headful

```bash
HEADLESS=false bin/rails test:system
```

View Coverage:

Open `coverage/index.html`

## Documentation

See [docs](https://phac-nml.github.io/irida-next/).
