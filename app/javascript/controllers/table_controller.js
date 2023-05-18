import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["rowSelection"];

  connect() {
    this.localStorageKey = window.location;
    this.localStorageValue = new Map();
  }

  update() {
    this.rowSelectionTargets.map((row) => {
      this.localStorageValue.set(row.value, row.checked);
    });
    localStorage.setItem(
      this.localStorageKey,
      JSON.stringify([...this.localStorageValue])
    );
  }
}
