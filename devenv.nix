{ pkgs, lib, config, inputs, ... }:

lib.mkMerge [
  {
    env.GA4GH_WES_URL = "http://localhost:1122";
    env.PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright.passthru.browsers}";
    env.PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS="true";

    # https://devenv.sh/packages/
    packages = with pkgs; [
      pkg-config
      libyaml.dev
      openssl.dev
      coreutils
      postgresql_14
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
      versionFile = ./.ruby-version;
      bundler.enable = false; # don't install bundler package from nix as this is already included with ruby
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

    # https://devenv.sh/tests/
    enterTest = ''
      echo "Running tests"
      git --version | grep --color=auto "${pkgs.git.version}"
    '';

    # See full reference at https://devenv.sh/reference/options/
  }
  (lib.mkIf pkgs.stdenv.isLinux {
    enterShell = ''
      # add libnss_sss.so.2 to LD_PRELOAD if it exists, to avoid issues with SSSD and NSS
      LIBNSS_SSS_PATH=$(find /lib /usr/lib /lib64 /usr/lib64 -name "libnss_sss.so.2" 2>/dev/null | head -n 1)
      if [ -n "$LIBNSS_SSS_PATH" ]; then
        export LD_PRELOAD="$LIBNSS_SSS_PATH"
      fi
    '';
  })
]
