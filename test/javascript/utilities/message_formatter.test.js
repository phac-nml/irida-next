import { describe, it, expect } from "vitest";
import { t } from "../../../app/javascript/utilities/message_formatter.js";

describe("message_formatter", () => {
  it("replaces placeholders with provided values", () => {
    expect(t("Hello %{name}!", { name: "Alice" })).toBe("Hello Alice!");
  });

  it("replaces multiple occurrences of the same placeholder", () => {
    expect(t("%{name} likes %{name}", { name: "Rails" })).toBe(
      "Rails likes Rails",
    );
  });

  it("supports multiple placeholder keys", () => {
    expect(t("%{count} %{item} processed", { count: 3, item: "files" })).toBe(
      "3 files processed",
    );
  });

  it("leaves placeholders that are not provided", () => {
    expect(t("Hello %{name} from %{city}", { name: "Alice" })).toBe(
      "Hello Alice from %{city}",
    );
  });

  it("returns template unchanged when vars are omitted", () => {
    expect(t("No substitutions %{here}")).toBe("No substitutions %{here}");
  });
});
