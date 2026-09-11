import { defineConfig } from "vitest/config";
import { resolve } from "path";
import { fileURLToPath } from "url";

const jsRoot = resolve(
  fileURLToPath(new URL("app/javascript", import.meta.url)),
);

const fullCoverageFiles = [
  'app/javascript/controllers/action_button_controller.js',
  'app/javascript/controllers/clipboard_controller.js',
  'app/javascript/controllers/colour_mode_controller.js',
  'app/javascript/controllers/collapsible_controller.js',
  'app/javascript/controllers/combobox/utils.js',
  'app/javascript/controllers/combobox/v1_controller.js',
  'app/javascript/controllers/confirmation_controller.js',
  'app/javascript/controllers/copy_controller.js',
  'app/javascript/controllers/experimental_feature_toggle_controller.js',
  'app/javascript/controllers/filters_controller.js',
  'app/javascript/controllers/layout_controller.js',
  'app/javascript/controllers/metadata_toggle_controller.js',
  'app/javascript/controllers/refresh_controller.js',
  'app/javascript/controllers/selection_controller.js',
  'app/javascript/controllers/sidebar_item_controller.js',
  'app/javascript/controllers/sortable_lists/v1/two_lists_selection_controller.js',
  'app/javascript/controllers/spinner_controller.js',
  'app/javascript/controllers/table_selection_controller.js',
  'app/javascript/controllers/token_controller.js',
  'app/javascript/controllers/treegrid_controller.js',
  'app/javascript/controllers/viral/alert_controller.js',
  'app/javascript/controllers/viral/dialog_controller.js',
  'app/javascript/controllers/viral/dialog_trigger_controller.js',
  'app/javascript/controllers/viral/flash_controller.js',
  'app/javascript/controllers/workflow_selection_controller.js',
  'app/javascript/utilities/collection.js',
  'app/javascript/utilities/dialog.js',
  'app/javascript/utilities/flash.js',
  'app/javascript/utilities/floating_dropdown.js',
  'app/javascript/utilities/focus.js',
  'app/javascript/utilities/form.js',
  'app/javascript/utilities/live_region.js',
  'app/javascript/utilities/message_formatter.js',
  'app/javascript/utilities/progress_window.js',
  'app/javascript/utilities/refresh.js',
  'app/javascript/utilities/styles.js',
  'app/javascript/utilities/word_connector.js',
  'app/javascript/**/*.js',
  'app/javascript/application.js',
  'app/javascript/active_admin_navigation.js',
  'app/javascript/controllers/index.js',
  'app/javascript/controllers/application.js',
  'app/javascript/controllers/combobox_datepicker/constants.js',
  'app/javascript/workers/**/*.js',
  'app/javascript/controllers/email_input_controller.js',
  'app/javascript/controllers/form_error_summary_controller.js',
];

const fullCoverageThresholds = Object.fromEntries(
  fullCoverageFiles.map((file) => [
    file,
    {
      statements: 100,
      branches: 100,
      functions: 100,
      lines: 100,
    },
  ]),
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
        "app/javascript/workers/**/*.js",
      ],
      // Ratchet allowlist: add a path here once it reaches full coverage.
      thresholds: fullCoverageThresholds,
    },
  },
});
