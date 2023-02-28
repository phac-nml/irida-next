import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["name", "path"];

  initialize() {
    this.pathTarget.placeholder = this.#slugify(this.nameTarget.placeholder);
  }

  nameChanged() {
    this.pathTarget.value = this.#slugify(this.nameTarget.value);
  }

  #slugify(string) {
    return string
      .toLowerCase()
      .trim()
      .replace(/[^\w ]+/g, "")
      .replace(/ +/g, "-");
  }
}
