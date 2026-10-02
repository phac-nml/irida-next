import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

const configSource = readFileSync("vitest.config.js", "utf8");

describe("Vitest coverage configuration", () => {
  it("enforces ratchet thresholds per source file", () => {
    expect(configSource).toMatch(/thresholds:\s*\{[\s\S]*perFile:\s*true/);
    expect(configSource).toContain("...fullCoverageThresholds");
    expect(configSource).toMatch(/statements:\s*100/);
    expect(configSource).toMatch(/branches:\s*100/);
    expect(configSource).toMatch(/functions:\s*100/);
    expect(configSource).toMatch(/lines:\s*100/);
  });

  it("measures the complete JavaScript source tree", () => {
    expect(configSource).toContain('include: ["app/javascript/**/*.js"]');
    expect(configSource).toContain(
      '"app/javascript/workers/linelist_import_worker.js"',
    );
  });
});
