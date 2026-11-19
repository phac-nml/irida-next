{ pkgs, lib, config, inputs, ... }:

let
  # Override for ruby-3.4.13: nixpkgs-ruby's published versions.json does not
  # yet include this release (fixing the GHSA-34m4-m9fh-gqp5 et al. Regexp/String
  # advisories), so build it directly from the upstream source tarball using
  # nixpkgs-ruby's own package function until upstream catches up.
  ruby_3_4_13 = pkgs.callPackage "${inputs.nixpkgs-ruby}/ruby/package-fn.nix" {
    version = "3.4.13";
    versionSource = {
      url = "https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.13.tar.gz";
      sha256 = "d0d3bf3dd8c224a3c3b7ecd816a0f1b2cbcf4f87b5afcbdbe91d3fef177f351a";
    };
    versionComparison = import "${inputs.nixpkgs-ruby}/lib/version-comparison.nix";
  };
in
lib.mkMerge [
  {
    env.GA4GH_WES_URL = "http://localhost:1122";
    env.PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright.passthru.browsers}";
    env.PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS="true";
    env.POETRY_DATA_DIR = "${config.devenv.state}/poetry/data";
    env.POETRY_CACHE_DIR = "${config.devenv.state}/poetry/cache";

    # pin nextflow to 25.10.2
    overlays = [
      (final: prev: {
        nextflow = inputs.nextflow-pin.legacyPackages.${prev.stdenv.hostPlatform.system}.nextflow.overrideAttrs (oldAttrs: {
          system = prev.stdenv.system;
          postPatch = ''
            # Nextflow invokes the constant "/bin/bash" (not as a shebang) at
            # several locations so we fix that globally. However, when running inside
            # a container, we actually *want* "/bin/bash". Thus the global fix needs
            # to be reverted for this specific use case.
            substituteInPlace modules/nextflow/src/main/groovy/nextflow/executor/BashWrapperBuilder.groovy \
              --replace-fail "['/bin/bash'," "['${prev.bash}/bin/bash'," \
              --replace-fail "if( containerBuilder ) {" "if( containerBuilder ) {
                        launcher = launcher.replaceFirst(\"/nix/store/.*/bin/bash\", \"/bin/bash\")"
          '';
        });
      })
    ];

    # https://devenv.sh/packages/
    packages = with pkgs; [
      pkg-config
      libyaml.dev
      openssl.dev
      coreutils
      postgresql_18
      nextflow
      nodejs_24
      jq
      file
      yq
      playwright-test
      gh
    ];

    # https://devenv.sh/languages/
    languages.ruby = {
      enable = true;
      # NOTE: nixpkgs-ruby's versions.json does not have "3.4.13" yet, so
      # versionFile/version (which both resolve via nixpkgs-ruby.lib) can't be
      # used here without erroring. .ruby-version still declares "3.4.13" for
      # Bundler/rbenv/CI; `package` below builds that same version directly so
      # the two stay in sync.
      package = ruby_3_4_13;
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
      version = "3.13.14";
      venv.enable = true;
      venv.requirements = ''
        poetry
      '';
    };

    # https://devenv.sh/processes/
    # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";
    processes.sapporo-service = {
      ports.http.allocate = 1122;
      exec = ''
        SKIP_CHOWN_OUTPUTS=True SAPPORO_HOST=0.0.0.0 SAPPORO_PORT=${toString config.processes.sapporo-service.ports.http.value} SAPPORO_DEBUG=True SAPPORO_RUN_SH=${config.devenv.state}/sapporo-service/sapporo/run_irida_next.sh poetry run sapporo
      '';
      cwd = "${config.devenv.state}/sapporo-service/sapporo";
    };

    # https://devenv.sh/services/
    services.postgres = {
      enable = true;
      package = pkgs.postgresql_18;
      createDatabase = false;
      port = 5432;
      initialScript = ''
        CREATE ROLE test LOGIN SUPERUSER PASSWORD 'test';
        CREATE EXTENSION IF NOT EXISTS hstore;
        CREATE EXTENSION IF NOT EXISTS pg_trgm;
      '';
      listen_addresses = "localhost";
    };

    # https://devenv.sh/scripts/
    scripts.install-ruby-lsp = {
      exec = ''
        newestAvailableRubyLspVersion="$(gem search ruby-lsp -r | grep 'ruby-lsp ' | awk '{print $2}' | tr -d '()')";
        newestInstalledRubyLspVersion="$(gem list ruby-lsp | grep 'ruby-lsp ' | awk '{print $2}' | tr -d '(),')";

        if [ "$newestInstalledRubyLspVersion" != "$newestAvailableRubyLspVersion" ]; then
          echo "❌ ruby-lsp version installed does not match newest available version of $newestAvailableRubyLspVersion."
          gem install ruby-lsp
        else
          echo "✅ ruby-lsp version installed matches newest available version."
        fi

        echo
      '';
      description = "Install ruby-lsp gem";
    };

    scripts.validate-playwright = {
      exec = ''
        playwrightNpmVersion="$(pnpm list playwright --lockfile-only | grep playwright | awk -F'@' '{print $2}')"

        echo "❄️ Playwright nix version: ${pkgs.playwright-test.version}"
        echo "📦 Playwright npm version: $playwrightNpmVersion"

        if [ "${pkgs.playwright-test.version}" != "$playwrightNpmVersion" ]; then
            echo "❌ Playwright versions in nix (in devenv.yaml) and npm (in package.json) are not the same! Please adapt the configuration."
        else
            echo "✅ Playwright versions in nix and npm are the same"
        fi

        echo
        env | grep ^PLAYWRIGHT
      '';
      description = "Validate playwright";
    };

    # https://devenv.sh/basics/
    enterShell = ''
      install-ruby-lsp
      validate-playwright
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
        mkdir -p sapporo/runs/.nextflow
        printf "docker {\n\tenabled = true\n\trunOptions = '--network host'\n}" > sapporo/runs/.nextflow/config
      '';
      cwd = "${config.devenv.state}";
      before = [ "devenv:processes:sapporo-service" ];
    };

    # https://devenv.sh/tests/
    enterTest = ''
      echo "Running tests"
      git --version | grep --color=auto "${pkgs.git.version}"
    '';

    # See full reference at https://devenv.sh/reference/options/
  }
  (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    enterShell = ''
      # add libnss_sss.so.2 to LD_PRELOAD if it exists, to avoid issues with SSSD and NSS
      LIBNSS_SSS_PATH=$(find /lib /usr/lib /lib64 /usr/lib64 -name "libnss_sss.so.2" 2>/dev/null | head -n 1)
      if [ -n "$LIBNSS_SSS_PATH" ]; then
        export LD_PRELOAD="$LIBNSS_SSS_PATH"
      fi
    '';
  })
]
