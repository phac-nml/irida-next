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
      "utilities/live_region": resolve(jsRoot, "utilities/live_region.js"),
      "utilities/advanced_search_focus": resolve(
        jsRoot,
        "utilities/advanced_search_focus.js",
      ),
      "utilities/flash": resolve(jsRoot, "utilities/flash.js"),
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
      thresholds: {
        perFile: true,
        statements: 100,
        branches: 100,
        functions: 100,
        lines: 100,
      },
    },
  },
});
