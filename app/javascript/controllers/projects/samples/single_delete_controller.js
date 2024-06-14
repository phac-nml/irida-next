import { Controller } from "@hotwired/stimulus";

// populates confirmation dialogue with description containing number of samples and samples selected for deletion
export default class extends Controller {
  static values = {
    storageKey: {
      type: String,
      default: location.protocol + "//" + location.host + location.pathname,
    },
    deleteId: {
      type: String
    }
  }

  clear() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    )
    if (storageValues.includes(this.deleteIdValue)) {
      const filteredStorageValues = storageValues.filter(e => e !== this.deleteIdValue)
      sessionStorage.setItem(this.storageKeyValue, JSON.stringify(filteredStorageValues))
    }
  }
}
