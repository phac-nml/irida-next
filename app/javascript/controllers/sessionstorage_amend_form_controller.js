import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

export default class extends Controller {
  static targets = ["field"];
  static outlets = ["infinite-scroll"];

  static values = {
    fieldName: String,
    page: Number,
    storageKey: {
      type: String,
      default: `${location.protocol}//${location.host}${location.pathname}`,
    },
  };

  connect() {
    if (!this.hasInfiniteScrollOutlet) {
      this.#createAllHiddenFormFields();
    }
  }

  infiniteScrollOutletConnected(outlet) {
    this.#createPageHiddenFormFields();
    if(this.pageValue == 1) {
      outlet.submitForm()
    }
  }

  #createPageHiddenFormFields() {
    const itemsPerPage = 100;
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue),
    );
    if (storageValues) {
      const start = (this.pageValue - 1) * itemsPerPage;
      const end = this.pageValue * itemsPerPage;
      const storageValuesPage = storageValues.slice(start, end);
      for (const storageValue of storageValuesPage) {
        this.fieldTarget.appendChild(this.#createHiddenInput(this.fieldNameValue, storageValue));
      }
      this.fieldTarget.appendChild(this.#createHiddenInput("page", this.pageValue));
      this.fieldTarget.appendChild(this.#createHiddenInput("has_next", storageValuesPage.length===itemsPerPage));
    }
  }

  #createAllHiddenFormFields() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );
    if (storageValues) {
      for (const storageValue of storageValues) {
        this.fieldTarget.appendChild(this.#createHiddenInput(this.fieldNameValue, storageValue));
      }
    }
  }

  #createHiddenInput(name, value){
    const element = document.createElement("input");
    element.type = "hidden";
    element.id = name;
    element.name = name;
    element.value = value;
    return element;
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }
}
