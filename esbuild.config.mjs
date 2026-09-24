import { execFileSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import * as esbuild from "esbuild";

const root = dirname(fileURLToPath(import.meta.url));
const pathogenGemRoot = execFileSync("bundle", ["show", "pathogen_view_components"], {
  cwd: root,
  encoding: "utf8",
}).trim();
const production = process.env.NODE_ENV === "production" || process.env.RAILS_ENV === "production";
const hostPackages = [
  "@floating-ui/dom",
  "@hotwired/stimulus",
  "@hotwired/turbo-rails",
  "uuid",
];

const options = {
  absWorkingDir: root,
  entryPoints: {
    application: "app/javascript/application.js",
    active_admin: "app/javascript/active_admin.js",
    "workers/linelist_export_worker": "app/javascript/workers/linelist_export_worker.js",
    "workers/linelist_import_worker": "app/javascript/workers/linelist_import_worker.js",
  },
  outdir: "app/assets/builds",
  bundle: true,
  platform: "browser",
  format: "esm",
  target: "es2022",
  minify: production,
  sourcemap: !production,
  define: {
    "import.meta.env.DEV": String(!production),
    "process.env.NODE_ENV": JSON.stringify(production ? "production" : "development"),
  },
  alias: {
    controllers: join(root, "app/javascript/controllers"),
    utilities: join(root, "app/javascript/utilities"),
    pathogen_view_components: join(pathogenGemRoot, "app/assets/javascripts/pathogen_view_components"),
    ...Object.fromEntries(hostPackages.map((name) => [name, name])),
  },
};

if (process.argv.includes("--watch")) {
  const context = await esbuild.context(options);
  await context.watch();
} else {
  await esbuild.build(options);
}
