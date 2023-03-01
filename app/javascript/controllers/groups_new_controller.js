import { Controller } from "@hotwired/stimulus";
import slugify from "@sindresorhus/slugify";

export default class extends Controller {
  static targets = ["name", "path"];

  initialize() {
    this.pathTarget.placeholder = slugify(this.nameTarget.placeholder);
  }

  nameChanged() {
    this.pathTarget.value = slugify(this.nameTarget.value);
  }
}
