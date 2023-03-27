import { Controller } from "@hotwired/stimulus";
import slugify from "@sindresorhus/slugify";

export default class extends Controller {
  static targets = ["name", "path"];

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  /**
   * When the controller is initialized, set the placeholder for the
   * path input to be the slugified version of the name.
   */
  initialize() {
    this.pathTarget.placeholder = slugify(this.nameTarget.placeholder);
  }

  /**
   * Called when the name input changes, and updated the path
   * to be the slugified version of the name.
   */
  nameChanged() {
    this.pathTarget.value = slugify(this.nameTarget.value);
  }
}
