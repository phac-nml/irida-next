import { execSync } from "child_process";
import { writeFileSync } from "node:fs";

// Always use the last line of output since Bundler's DEBUG env will print additional lines.
const activeAdminPath = execSync("bundle show activeadmin", {
  encoding: "utf-8",
})
  .trim()
  .split(/\r?\n/)
  .pop();

const css = `@source "${activeAdminPath}/vendor/javascript/flowbite.js";
@source "${activeAdminPath}/plugin.js";
@source "${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}";
`;

writeFileSync("app/assets/stylesheets/activeadmin-source.generated.css", css);
