{ pkgs, lib, config, inputs, ... }:

lib.mkMerge [
  {
    env.GA4GH_WES_URL = "http://localhost:1122";

    # https://devenv.sh/packages/
    packages = with pkgs; [
      pkg-config
      libyaml.dev
      openssl.dev
      coreutils
      postgresql_14
      nextflow
      nodejs_24
      pnpm_10
      jq
      file
    ];

    # https://devenv.sh/languages/
    languages.ruby = {
      enable = true;
      versionFile = ./.ruby-version;
      bundler.enable = false; # don't install bundler package from nix as this is already included with ruby
    };

    languages.javascript = {
      enable = true;
      # Pin Corepack to Node 24 so pnpm/yarn shims run on Node 24
      package = pkgs.nodejs_24;
      corepack.enable = true;
    };

    languages.python = {
      enable = true;
      venv.enable = true;
      venv.requirements = ''
        poetry
      '';
    };

    process.manager.implementation = "honcho";

    # https://devenv.sh/processes/
    # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";
    processes.sapporo-service = {
      exec = ''
        SKIP_CHOWN_OUTPUTS=True SAPPORO_HOST=0.0.0.0 SAPPORO_PORT=1122 SAPPORO_DEBUG=True SAPPORO_RUN_SH=${config.git.root}/.devenv/sapporo-service/sapporo/run_irida_next.sh poetry run sapporo
      '';
      cwd = "${config.git.root}/.devenv/sapporo-service/sapporo";
    };

    # https://devenv.sh/services/
    services.postgres = {
      enable = true;
      package = pkgs.postgresql_14;
      createDatabase = false;
      initialScript = ''
        CREATE ROLE test LOGIN SUPERUSER PASSWORD 'test';
        CREATE EXTENSION IF NOT EXISTS hstore;
        CREATE EXTENSION IF NOT EXISTS pg_trgm;
      '';
      listen_addresses = "localhost";
    };

    # https://devenv.sh/basics/
    enterShell = ''
      ruby --version
      gem install ruby-lsp
    '';

    # https://devenv.sh/tasks/
    # tasks = {
    #   "myproj:setup".exec = "mytool build";
    #   "devenv:enterShell".after = [ "myproj:setup" ];
    # };
    tasks."sapporo:setup-data" = {
      exec = ''
        [ ! -d 'sapporo-service' ] && git clone https://github.com/phac-nml/sapporo-service.git
        cd sapporo-service
        git fetch --all
        git checkout main
        git branch -D irida-next &>/dev/null || true
        git checkout irida-next
        poetry install -v
      '';
      cwd = "${config.git.root}/.devenv";
      before = [ "devenv:processes:sapporo-service" ];
    };

    # https://devenv.sh/tests/
    enterTest = ''
      echo "Running tests"
      git --version | grep --color=auto "${pkgs.git.version}"
    '';

    # https://devenv.sh/git-hooks/
    git-hooks.hooks = {
      # RuboCop for Ruby files
      rubocop = {
        enable = true;
        name = "RuboCop";
        description = "Run RuboCop on changed Ruby files";
        entry = "bundle exec rubocop -a --force-exclusion";
        files = "\\.rb$";
        pass_filenames = true;
      };

      # Prettier for JS, CSS, config files
      prettier = {
        enable = true;
        name = "Prettier";
        description = "Format JS, CSS, and config files";
        entry = "pnpm exec prettier --write";
        files = "^(?!.*pnpm-lock\\.yaml$).*\\.(js|jsx|ts|tsx|css|json|md|yml|yaml)$";
        pass_filenames = true;
      };

      # herb formatter for ERB templates
      herb_formatter = {
        enable = true;
        name = "Herb Formatter";
        description = "Format ERB templates with herb";
        entry = "bundle exec herb html";
        files = "\\.erb$";
        pass_filenames = true;
      };
    };

    # See full reference at https://devenv.sh/reference/options/
  }
  (lib.mkIf pkgs.stdenv.isLinux {
    # Additional Linux packages
    packages = [ pkgs.sssd ];

    env.LD_LIBRARY_PATH = "${pkgs.sssd}/lib";
  })
]
