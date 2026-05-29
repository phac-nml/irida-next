export default class WordConnector {
  // Private Fields

  #wordsConnector; // connector for 3 or more words, eg: ", "
  #twoWordsConnector; // connects two words, eg: " and "
  #lastWordConnector; // connects last word for 3 or more words, eg: ", and "

  // Initialize sentence constructor connectors
  constructor({
    wordsConnector = ", ",
    twoWordsConnector = " and ",
    lastWordConnector = ", and ",
  }) {
    this.#wordsConnector = wordsConnector;
    this.#twoWordsConnector = twoWordsConnector;
    this.#lastWordConnector = lastWordConnector;
  }

  // connect words based on array size
  connectWords(words) {
    if (Array.isArray(words)) {
      switch (words.length) {
        case 0:
          return "";
        case 1:
          return words[0];
        case 2:
          return `${words[0]}${this.#twoWordsConnector}${words[1]}`;
        default:
          return `${words.slice(0, -1).join(this.#wordsConnector)}${this.#lastWordConnector}${words[words.length - 1]}`;
      }
    } else {
      return words;
    }
  }
}
