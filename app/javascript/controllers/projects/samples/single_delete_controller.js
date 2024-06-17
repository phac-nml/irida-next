import { Controller } from "@hotwired/stimulus";

// removes sample from sessionstorage if it was checked/selected then removed using the remove link
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
      const newStorageValues = storageValues.filter(id => id !== this.deleteIdValue)
      sessionStorage.setItem(this.storageKeyValue, JSON.stringify(newStorageValues))
    }
  }
}
