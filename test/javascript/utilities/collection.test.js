import { describe, it, expect, vi } from "vitest";
import {
  chunk,
  pick,
  omitBy,
} from "../../../app/javascript/utilities/collection.js";

describe("collection", () => {
  describe("chunk", () => {
    it("splits an array into chunks of the provided size", () => {
      expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]]);
    });

    it("returns a single chunk when size is larger than array length", () => {
      expect(chunk([1, 2, 3], 10)).toEqual([[1, 2, 3]]);
    });

    it("returns an empty array when input array is empty", () => {
      expect(chunk([], 3)).toEqual([]);
    });

    it("does not mutate the original array", () => {
      const input = [1, 2, 3, 4];
      chunk(input, 2);
      expect(input).toEqual([1, 2, 3, 4]);
    });
  });

  describe("pick", () => {
    it("returns a new object containing only the selected keys", () => {
      const result = pick({ id: 1, name: "Alice", role: "admin" }, [
        "name",
        "role",
      ]);
      expect(result).toEqual({ name: "Alice", role: "admin" });
    });

    it("includes missing keys with undefined values", () => {
      const result = pick({ id: 1 }, ["id", "name"]);
      expect(result).toEqual({ id: 1, name: undefined });
    });

    it("returns an empty object when no keys are requested", () => {
      expect(pick({ id: 1 }, [])).toEqual({});
    });
  });

  describe("omitBy", () => {
    it("omits entries where predicate returns true", () => {
      const result = omitBy({ a: 1, b: 2, c: 3 }, (value) => value % 2 === 0);
      expect(result).toEqual({ a: 1, c: 3 });
    });

    it("passes value and key to predicate", () => {
      const predicate = vi.fn(
        (value, key) => key === "secret" || value === null,
      );
      const input = { name: "Alice", secret: "token", bio: null };

      const result = omitBy(input, predicate);

      expect(result).toEqual({ name: "Alice" });
      expect(predicate).toHaveBeenCalledTimes(3);
      expect(predicate).toHaveBeenCalledWith("Alice", "name");
      expect(predicate).toHaveBeenCalledWith("token", "secret");
      expect(predicate).toHaveBeenCalledWith(null, "bio");
    });

    it("returns a new object and does not mutate the original object", () => {
      const input = { a: 1, b: 2 };
      const result = omitBy(input, (value) => value > 1);

      expect(result).toEqual({ a: 1 });
      expect(result).not.toBe(input);
      expect(input).toEqual({ a: 1, b: 2 });
    });
  });
});
