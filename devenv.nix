{ pkgs, lib, config, inputs, ... }:

{
  env.GA4GH_WES_URL = "http://localhost:1122";
  env.LD_LIBRARY_PATH = "${pkgs.sssd}/lib";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    pkg-config
    libyaml.dev
    openssl.dev
    coreutils
    sssd
    postgresql_14
    nodejs_24
    pnpm_10
    python313
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
      setuptools
      wheel
      pip
    '';
  };


  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";
  processes.sapporo-service = {
    exec = ''
      SAPPORO_HOST=0.0.0.0 SAPPORO_PORT=1122 SAPPORO_RUN_SH=${config.git.root}/.devenv/sapporo-service/sapporo/run_irida_next.sh sapporo
    '';
    cwd = "${config.git.root}/.devenv/sapporo-service/sapporo";
  };

  # https://devenv.sh/services/
  services.postgres = {
    enable = true;
    package = pkgs.postgresql_14;
    initialScript = ''
      CREATE ROLE postgres SUPERUSER;
      CREATE ROLE test LOGIN SUPERUSER PASSWORD 'test';
      CREATE EXTENSION IF NOT EXISTS hstore;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
    '';
    initialDatabases = [
      { name = "irida_next_development"; user = "test"; schema = ./db/structure.sql; }
      { name = "irida_next_jobs_development"; user = "test"; schema = ./db/jobs_structure.sql; }
    ];
    listen_addresses = "localhost";
  };

  # https://devenv.sh/basics/
  enterShell = ''
    ruby --version
    gem install ruby-lsp
    bundle
    pnpm install --frozen-lockfile
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
      git checkout irida-next
      git pull
      python3 -m pip install -e .
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
