import { defineConfig } from "vitest/config";
import { resolve } from "path";
import { fileURLToPath } from "url";

const jsRoot = resolve(
  fileURLToPath(new URL("app/javascript", import.meta.url)),
);

// Prefer PATHOGEN_VIEW_COMPONENTS_JS when set (CI / non-sibling checkouts).
// Default assumes a sibling pathogen-view-components checkout.
const pathogenJsRoot = resolve(
  process.env.PATHOGEN_VIEW_COMPONENTS_JS ||
    fileURLToPath(
      new URL(
        "../pathogen-view-components/app/assets/javascripts/pathogen_view_components",
        import.meta.url,
      ),
    ),
);

export default defineConfig({
  resolve: {
    alias: {
      pathogen_view_components: pathogenJsRoot,
      controllers: resolve(jsRoot, "controllers"),
      debounce: resolve("vendor/javascript/debounce.js"),
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
  },
});
