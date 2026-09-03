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
      tabbable: resolve("vendor/javascript/tabbable.js"),
      "utilities/live_region": resolve(jsRoot, "utilities/live_region.js"),
      "utilities/form": resolve(jsRoot, "utilities/form.js"),
      "utilities/focus": resolve(jsRoot, "utilities/focus.js"),
      "utilities/refresh": resolve(jsRoot, "utilities/refresh.js"),
      "utilities/styles": resolve(jsRoot, "utilities/styles.js"),
      "utilities/floating_dropdown": resolve(
        jsRoot,
        "utilities/floating_dropdown.js",
      ),
      "utilities/word_connector": resolve(
        jsRoot,
        "utilities/word_connector.js",
      ),
    },
  },
  test: {
    globals: true,
    environment: "jsdom",
    include: ["test/javascript/**/*.{test,spec}.{js,ts}"],
    setupFiles: ["./test/javascript/setup.js"],
    passWithNoTests: true,
    clearMocks: true,
    restoreMocks: true,
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
        "app/javascript/workers/**/*.js",
      ],
      // Ratchet allowlist: add a file/glob here once it reaches full coverage.
      thresholds: {
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
      },
    },
  },
});
