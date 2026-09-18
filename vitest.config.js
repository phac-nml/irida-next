import { defineConfig } from "vitest/config";
import { resolve } from "path";
import { fileURLToPath } from "url";

const jsRoot = resolve(
  fileURLToPath(new URL("app/javascript", import.meta.url)),
);

export default defineConfig({
  resolve: {
    alias: {
      controllers: resolve(jsRoot, "controllers"),
      debounce: resolve("vendor/javascript/debounce.js"),
      deepmerge: resolve("vendor/javascript/deepmerge.js"),
      "focus-trap": resolve("vendor/javascript/focus-trap.js"),
      tabbable: resolve("vendor/javascript/tabbable.js"),
      "utilities/live_region": resolve(jsRoot, "utilities/live_region.js"),
      "utilities/form": resolve(jsRoot, "utilities/form.js"),
      "utilities/focus": resolve(jsRoot, "utilities/focus.js"),
      "utilities/refresh": resolve(jsRoot, "utilities/refresh.js"),
      "utilities/styles": resolve(jsRoot, "utilities/styles.js"),
      "utilities/dialog": resolve(jsRoot, "utilities/dialog.js"),
      "utilities/message_formatter": resolve(
        jsRoot,
        "utilities/message_formatter.js",
      ),
      "utilities/progress_window": resolve(
        jsRoot,
        "utilities/progress_window.js",
      ),
      "utilities/floating_dropdown": resolve(
        jsRoot,
        "utilities/floating_dropdown.js",
      ),
      "utilities/word_connector": resolve(
        jsRoot,
        "utilities/word_connector.js",
      ),
      // `xlsx` ships via the import map in production and is not an installed
      // dependency; alias the bare specifier to a stub so tests can load the
      // downloader and mock the library per-case.
      xlsx: resolve(
        fileURLToPath(
          new URL("test/javascript/fixtures/xlsx_stub.js", import.meta.url),
        ),
      ),
    },
  },
  test: {
    globals: true,
    sequence: { shuffle: true },
    environment: "jsdom",
    environmentOptions: {
      jsdom: {
        url: "http://localhost:3000/",
      },
    },
    include: ["test/javascript/**/*.{test,spec}.{js,ts}"],
    setupFiles: ["./test/javascript/setup.js"],
    clearMocks: true,
    restoreMocks: true,
    unstubGlobals: true,
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      // Measure the whole JS surface so uncovered files stay visible.
      include: ["app/javascript/**/*.js"],
      // Bootstrapping and Web Worker entry modules run on import or in a worker
      // context and are not meaningfully unit-testable; exclude from measurement.
      exclude: [
        "app/javascript/application.js",
        "app/javascript/active_admin_navigation.js",
        "app/javascript/controllers/index.js",
        "app/javascript/controllers/application.js",
        "app/javascript/controllers/combobox_datepicker/constants.js",
        // Import worker entry module runs in a worker context and is not yet
        // unit-tested; the export worker is covered and gated below.
        "app/javascript/workers/linelist_import_worker.js",
      ],
      // Ratchet allowlist: add a file/glob here once it reaches full coverage.
      thresholds: {
        "app/javascript/controllers/collapsible_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/sidebar_item_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/clipboard_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/copy_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/action_button_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/confirmation_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/filters_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/metadata_toggle_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/token_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },

        "app/javascript/controllers/sortable_lists/v1/two_lists_selection_controller.js":
          {
            statements: 100,
            branches: 100,
            functions: 100,
            lines: 100,
          },
        "app/javascript/controllers/workflow_selection_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/treegrid_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/collection.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/live_region.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/message_formatter.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/word_connector.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/form.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/dialog.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/flash.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/focus.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/floating_dropdown.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/progress_window.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/styles.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/utilities/refresh.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/experimental_feature_toggle_controller.js":
          {
            statements: 100,
            branches: 100,
            functions: 100,
            lines: 100,
          },
        "app/javascript/controllers/combobox/utils.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/combobox/v1_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/viral/dialog_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/viral/dialog_trigger_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/viral/flash_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/viral/alert_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/linelist_export_controller.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/linelist_export/downloader.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/linelist_export/selection.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/controllers/linelist_export/worker_client.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
        "app/javascript/workers/linelist_export_worker.js": {
          statements: 100,
          branches: 100,
          functions: 100,
          lines: 100,
        },
      },
    },
  },
});
