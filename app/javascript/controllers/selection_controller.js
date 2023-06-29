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

    const storageValue = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );

    if (storageValue) {
      this.rowSelectionTargets.map((row) => {
        if (storageValue.indexOf(row.value) > -1) {
          row.checked = true;
        }
      });
    } else {
      this.save([]);
    }
  }

  toggle(event) {
    const newStorageValue = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );

    if (event.target.checked) {
      newStorageValue.push(event.target.value);
    } else {
      const index = newStorageValue.indexOf(event.target.value);
      if (index > -1) {
        newStorageValue.splice(index, 1);
      }
    }
    this.save(newStorageValue);
  }

  save(storageValue) {
    sessionStorage.setItem(
      this.storageKeyValue,
      JSON.stringify([...storageValue])
    );
  }
}
