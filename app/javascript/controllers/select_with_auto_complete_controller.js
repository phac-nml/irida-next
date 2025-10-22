import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

export default class SelectWithAutoCompleteController extends Controller {
  connect() {
    console.debug("SelectWithAutoCompleteController: Connected");
    new TomSelect(this.element, {
      render: {
        optgroup: function (data, escape) {
          var optgroup = document.createElement("div");
          optgroup.className = "optgroup";
          optgroup.role = "group";
          optgroup.setAttribute("aria-labelledby", data.group.value);
          var optgroup_header = document.createElement("div");
          optgroup_header.className = "optgroup-header";
          optgroup_header.role = "presentation";
          optgroup_header.innerText = data.group.label;
          optgroup_header.id = data.group.value;
          optgroup.appendChild(optgroup_header);
          optgroup.appendChild(data.options);
          return optgroup;
        },
        optgroup_header: function (data, escape) {
          return "";
        },
      },
    });
  }

  disconnect() {
    console.debug("SelectWithAutoCompleteController: Disconnected");
    if (this.element.tomselect) {
      this.element.tomselect.destroy();
    }
  }
}
