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
    this.element.setAttribute("data-controller-connected", "true");

    if (sessionStorage.getItem(this.storageKeyValue)) {
      this.rowSelectionTargets.map((row) => {
        if (
          new Map(JSON.parse(sessionStorage.getItem(this.storageKeyValue))).get(
            row.value
          )
        ) {
          row.checked = true;
        }
      });
    } else {
      let newStorageValue = new Map();
      this.rowSelectionTargets.map((row) => {
        newStorageValue.set(row.value, row.checked);
      });
      this.save(newStorageValue);
    }
  }

  toggle(event) {
    let newStorageValue = new Map(
      JSON.parse(sessionStorage.getItem(this.storageKeyValue))
    ).set(event.target.value, event.target.checked);
    this.save(newStorageValue);
  }

  save(storageValue) {
    sessionStorage.setItem(
      this.storageKeyValue,
      JSON.stringify([...storageValue])
    );
  }
}
