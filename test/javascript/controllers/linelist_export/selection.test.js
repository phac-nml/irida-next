import { afterEach, describe, expect, it } from "vitest";
import {
  csrfToken,
  selectedFormat,
  selectedMetadataFields,
  selectedNamespaceId,
  selectedSampleIds,
  selectionStorageKey,
} from "../../../../app/javascript/controllers/linelist_export/selection.js";

describe("linelist export selection", () => {
  afterEach(() => {
    document.body.replaceChildren();
    document.head.replaceChildren();
  });

  describe("selectedMetadataFields", () => {
    it("returns trimmed non-empty field labels from the selected list", () => {
      document.body.innerHTML = `
        <ul id="selected-list">
          <li><span>drag</span><span>  age  </span></li>
          <li><span>drag</span><span>country</span></li>
        </ul>`;
      expect(selectedMetadataFields(document.body)).toEqual(["age", "country"]);
    });

    it("skips items with no last child or blank text", () => {
      document.body.innerHTML = `
        <ul id="selected-list">
          <li></li>
          <li><span>drag</span><span>   </span></li>
          <li><span>drag</span><span>city</span></li>
        </ul>`;
      expect(selectedMetadataFields(document.body)).toEqual(["city"]);
    });
  });

  describe("selectedFormat", () => {
    it("returns the checked format value", () => {
      document.body.innerHTML = `
        <input type="radio" name="data_export[export_parameters][linelist_format]" value="csv">
        <input type="radio" name="data_export[export_parameters][linelist_format]" value="xlsx" checked>`;
      expect(selectedFormat(document.body)).toBe("xlsx");
    });

    it("defaults to csv when nothing is checked", () => {
      document.body.innerHTML = `
        <input type="radio" name="data_export[export_parameters][linelist_format]" value="xlsx">`;
      expect(selectedFormat(document.body)).toBe("csv");
    });
  });

  describe("selectedNamespaceId", () => {
    it("returns the namespace input value", () => {
      document.body.innerHTML = `
        <input name="data_export[export_parameters][namespace_id]" value="42">`;
      expect(selectedNamespaceId(document.body)).toBe("42");
    });

    it("returns an empty string when the input is absent", () => {
      document.body.innerHTML = "";
      expect(selectedNamespaceId(document.body)).toBe("");
    });
  });

  describe("selectedSampleIds", () => {
    it("returns an empty array when nothing is stored", () => {
      expect(selectedSampleIds("missing")).toEqual([]);
    });

    it("parses a stored JSON array", () => {
      sessionStorage.setItem("key", JSON.stringify(["1", "2"]));
      expect(selectedSampleIds("key")).toEqual(["1", "2"]);
    });

    it("returns an empty array when the stored value is not an array", () => {
      sessionStorage.setItem("key", JSON.stringify({ a: 1 }));
      expect(selectedSampleIds("key")).toEqual([]);
    });

    it("returns an empty array when the stored value is invalid JSON", () => {
      sessionStorage.setItem("key", "not-json");
      expect(selectedSampleIds("key")).toEqual([]);
    });

    it("accepts a custom storage object", () => {
      const store = new Map([["k", JSON.stringify(["a"])]]);
      const storage = { getItem: (key) => store.get(key) ?? null };
      expect(selectedSampleIds("k", storage)).toEqual(["a"]);
    });
  });

  describe("selectionStorageKey", () => {
    it("builds a key from the location origin and path", () => {
      const loc = { protocol: "https:", host: "example.test", pathname: "/x" };
      expect(selectionStorageKey(loc)).toBe("https://example.test/x");
    });

    it("defaults to the current location", () => {
      expect(selectionStorageKey()).toBe(
        `${location.protocol}//${location.host}${location.pathname}`,
      );
    });
  });

  describe("csrfToken", () => {
    it("reads the token from the meta tag", () => {
      document.head.innerHTML = `<meta name="csrf-token" content="abc123">`;
      expect(csrfToken(document)).toBe("abc123");
    });

    it("returns an empty string when the meta tag is missing", () => {
      expect(csrfToken(document)).toBe("");
    });
  });
});
