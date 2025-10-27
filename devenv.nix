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
      bundler.enable = true;
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
    # git-hooks.hooks.shellcheck.enable = true;

    # See full reference at https://devenv.sh/reference/options/
  }
  (lib.mkIf pkgs.stdenv.isLinux {
    # Additional Linux packages
    packages = [ pkgs.sssd ];

    env.LD_LIBRARY_PATH = "${pkgs.sssd}/lib";
  })
]
