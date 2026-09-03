import { describe, it, expect } from "vitest";
import WordConnector from "../../../app/javascript/utilities/word_connector.js";

describe("word_connector", () => {
  const wordConnector = new WordConnector({
    wordsConnector: ", ",
    twoWordsConnector: " and ",
    lastWordConnector: ", and ",
  });
  describe("connectWords", () => {
    it("one word", () => {
      const connectedWords = wordConnector.connectWords(["word1"]);

      expect(connectedWords).toBe("word1");
    });

    it("empty array", () => {
      const connectedWords = wordConnector.connectWords([]);

      expect(connectedWords).toBe("");
    });

    it("two words", () => {
      const connectedWords = wordConnector.connectWords(["word1", "word2"]);

      expect(connectedWords).toBe("word1 and word2");
    });

    it("three words", () => {
      const connectedWords = wordConnector.connectWords([
        "word1",
        "word2",
        "word3",
      ]);

      expect(connectedWords).toBe("word1, word2, and word3");
    });

    it("four words", () => {
      const connectedWords = wordConnector.connectWords([
        "word1",
        "word2",
        "word3",
        "word4",
      ]);

      expect(connectedWords).toBe("word1, word2, word3, and word4");
    });

    it("string", () => {
      const connectedWords = wordConnector.connectWords("word1, word2, word3");

      expect(connectedWords).toBe("word1, word2, word3");
    });
  });

  describe("default connectors", () => {
    const defaultConnector = new WordConnector({});

    it("uses the default two-word connector", () => {
      expect(defaultConnector.connectWords(["word1", "word2"])).toBe(
        "word1 and word2",
      );
    });

    it("uses the default words and last-word connectors", () => {
      expect(defaultConnector.connectWords(["word1", "word2", "word3"])).toBe(
        "word1, word2, and word3",
      );
    });
  });
});
