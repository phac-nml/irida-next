# IRIDA Next

> IRIDA Next is an open source bioinformatics platform for the storage, management, and analysis of genomic sequences and metadata.

## Contributing

[`devenv`](https://devenv.sh/) is used to provide a reproducible development environment for this project. Follow the [getting started instructions](https://devenv.sh/getting-started/) (note: I recommend going with single-user mode for nix which can be found under the `WSL2` tab, and then installing `deven` under the `Nix profiles (requires experimental flags)`).

Note: to use `Nix profiles` you will need to create the following file with the following content

`~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

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

## Pre-commit Hooks & Formatting

This project uses [devenv.sh git-hooks](https://devenv.sh/git-hooks/) to automatically format and lint code before each commit. The following tools are run on staged files:

- **RuboCop**: Ruby files (`.rb`) are auto-corrected and linted
- **Prettier**: JavaScript, TypeScript, CSS, Markdown, YAML, and config files are formatted
- **erb-formatter**: ERB templates (`.erb`) are formatted for consistent style

### How it works

- Hooks are configured in `devenv.nix` and activated automatically when you run `direnv reload` or enter the devenv shell
- On commit, only staged files matching the patterns are checked and auto-fixed
- You can bypass hooks with `git commit --no-verify` (not recommended)

### Manual formatting

- Run all formatters manually:

  ```bash
  bundle exec rubocop -a
  pnpm run format
  bundle exec erb-format --write '**/*.erb'
  ```

### CI checks

- The CI workflow (`.github/workflows/linting.yml`) runs RuboCop, Prettier, and erb-formatter on every pull request
- PRs will fail if formatting or linting issues are detected

### Ignore files

- `.prettierignore` excludes build outputs, dependencies, and generated files from Prettier formatting
