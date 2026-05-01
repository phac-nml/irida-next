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
      "utilities/form": resolve(jsRoot, "utilities/form.js"),
      "utilities/focus": resolve(jsRoot, "utilities/focus.js"),
      "utilities/refresh": resolve(jsRoot, "utilities/refresh.js"),
      "utilities/styles": resolve(jsRoot, "utilities/styles.js"),
      "utilities/floating_dropdown": resolve(
        jsRoot,
        "utilities/floating_dropdown.js",
      ),
      workers: resolve(jsRoot, "workers"),
      xlsx: resolve(
        fileURLToPath(
          new URL("test/javascript/mocks/xlsx.js", import.meta.url),
        ),
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
