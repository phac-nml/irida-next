import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["name", "path"];

  initialize() {
    this.pathTarget.placeholder = this.#slugify(this.nameTarget.placeholder);
  }

  connect() {
    console.log("Connected to groups_new.js");
  }

  nameChanged() {
    this.pathTarget.value = this.#slugify(this.nameTarget.value);
  }

  #slugify(string) {
    return string
      .toLowerCase()
      .replace(/[^\w ]+/g, "")
      .replace(/ +/g, "-");
  }
}
