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
    if (localStorage.getItem(this.storageKeyValue)) {
      this.rowSelectionTargets.map((row) => {
        if (
          new Map(JSON.parse(localStorage.getItem(this.storageKeyValue))).get(
            row.value
          )
        ) {
          row.checked = true;
        }
      });
    } else {
      let newLocalStorageValue = new Map();
      this.rowSelectionTargets.map((row) => {
        newLocalStorageValue.set(row.value, row.checked);
      });
      this.save(newLocalStorageValue);
    }
  }

  toggle(event) {
    let newLocalStorageValue = new Map(
      JSON.parse(localStorage.getItem(this.storageKeyValue))
    ).set(event.target.value, event.target.checked);
    this.save(newLocalStorageValue);
  }

  save(localStorageValue) {
    localStorage.setItem(
      this.storageKeyValue,
      JSON.stringify([...localStorageValue])
    );
  }
}
