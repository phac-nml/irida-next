import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["rowSelection"];

  connect() {
    this.localStorageKey = window.location;
    this.localStorageValue = new Map(
      JSON.parse(localStorage.getItem(window.location))
    );

    if (this.localStorageValue.size === 0) {
      this.rowSelectionTargets.map((row) => {
        this.localStorageValue.set(row.value, row.checked);
      });
      this.save();
    } else {
      this.rowSelectionTargets.map((row) => {
        if (this.localStorageValue.get(row.value)) {
          row.checked = true;
        }
      });
    }
  }

  toggle(event) {
    this.localStorageValue.set(event.target.value, event.target.checked);
    this.save();
  }

  save() {
    localStorage.setItem(
      this.localStorageKey,
      JSON.stringify([...this.localStorageValue])
    );
  }
}
