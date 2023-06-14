import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["rowSelection"];
  static values = {
    storageKey: {
      type: String,
      default: location.protocol + "//" + location.host + location.pathname,
    },
  };

  connect() {
    this.localStorageValue = new Map(
      JSON.parse(localStorage.getItem(this.storageKeyValue))
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
      this.storageKeyValue,
      JSON.stringify([...this.localStorageValue])
    );
  }
}
