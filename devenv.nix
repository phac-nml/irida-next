{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    pkg-config
    libyaml.dev
    openssl.dev
    coreutils
    nodejs_24
    pnpm_10
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


  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

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

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
