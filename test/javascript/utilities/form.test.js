import { describe, it, expect } from "vitest";
import {
  createHiddenInput,
  formDataToJsonParams,
  normalizeParams,
  ParameterTypeError,
} from "../../../app/javascript/utilities/form.js";

describe("form", () => {
  describe("createHiddenInput", () => {
    it("returns an input element with type=hidden", () => {
      const input = createHiddenInput("foo", "bar");
      expect(input.tagName).toBe("INPUT");
      expect(input.type).toBe("hidden");
    });

    it("sets name and value attributes", () => {
      const input = createHiddenInput("user_id", "42");
      expect(input.name).toBe("user_id");
      expect(input.value).toBe("42");
    });
  });

  describe("formDataToJsonParams", () => {
    it("converts flat key-value pairs", () => {
      const fd = new FormData();
      fd.append("name", "Alice");
      fd.append("age", "30");
      expect(formDataToJsonParams(fd)).toEqual({ name: "Alice", age: "30" });
    });

    it("converts nested params like user[name]", () => {
      const fd = new FormData();
      fd.append("user[name]", "Jane");
      fd.append("user[email]", "jane@example.com");
      expect(formDataToJsonParams(fd)).toEqual({
        user: { name: "Jane", email: "jane@example.com" },
      });
    });

    it("converts array params like ids[]", () => {
      const fd = new FormData();
      fd.append("ids[]", "1");
      fd.append("ids[]", "2");
      fd.append("ids[]", "3");
      const result = formDataToJsonParams(fd);
      expect(result).toEqual({ ids: ["1", "2", "3"] });
    });
  });

  describe("ParameterTypeError", () => {
    it("is an instance of Error", () => {
      const err = new ParameterTypeError("test error");
      expect(err).toBeInstanceOf(Error);
    });

    it("has name set to ParameterTypeError", () => {
      const err = new ParameterTypeError("test error");
      expect(err.name).toBe("ParameterTypeError");
    });

    it("carries the provided message", () => {
      const err = new ParameterTypeError("bad param");
      expect(err.message).toBe("bad param");
    });
  });

  describe("normalizeParams", () => {
    it("sets a plain key", () => {
      const params = {};
      normalizeParams(params, "simple", "val", 0);
      expect(params.simple).toBe("val");
    });

    it("sets nested key user[name]", () => {
      const params = {};
      normalizeParams(params, "user[name]", "Jane", 0);
      expect(params.user.name).toBe("Jane");
    });

    it("builds array for ids[]", () => {
      const params = {};
      normalizeParams(params, "ids[]", "1", 0);
      normalizeParams(params, "ids[]", "2", 0);
      expect(params.ids).toEqual(["1", "2"]);
    });

    it("throws ParameterTypeError when array expected but hash given", () => {
      const params = { tags: { existing: "value" } };
      expect(() => normalizeParams(params, "tags[]", "new", 0)).toThrow(
        ParameterTypeError,
      );
    });

    it("returns the params object", () => {
      const params = {};
      const result = normalizeParams(params, "key", "value", 0);
      expect(result).toBe(params);
    });
  });
});
