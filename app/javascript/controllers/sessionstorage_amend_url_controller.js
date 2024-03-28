import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    fieldName: String,
    redirect: String,
    page: Number,
    storageKey: {
      type: String,
      default: location.protocol + "//" + location.host + location.pathname,
    },
  };

  connect() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );

    if (storageValues) {
      //should we use a js pagination library?
      const start = (this.pageValue - 1) * 10;
      const end = this.pageValue * 10 - 1;
      const pageStorageValues = storageValues.slice(start, end);
      const url = new URL(this.redirectValue);
      for (const pageStorageValue of pageStorageValues) {
        url.searchParams.append(this.fieldNameValue, pageStorageValue);
      }
      url.searchParams.set("page", this.pageValue);
      url.searchParams.set("next", pageStorageValues.length);
      this.element.setAttribute("loading", "lazy");
      this.element.src = url;
    }
  }
}
