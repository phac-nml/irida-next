import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {

  static targets = ["field"];

  static values = {
    targetList: {
      type: String,
    }
  };

  connect() {
    console.log(this.targetListValue)
    let list = document.getElementById(this.targetListValue)
    console.log(list)
  }

  constructMetadataParams() {
    console.log('hello')
    const list = document.getElementById(this.targetListValue)
    const metadata_fields = list.getElementsByTagName("li")

    for (let metadata_field of metadata_fields) {
      this.fieldTarget.appendChild(
        createHiddenInput(
          `data_export[export_parameters][metadata_fields][]`,
          metadata_field.innerText
        )
      );
    }
  }
}
