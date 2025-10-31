import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

export default class TomSelectController extends Controller {
  connect() {
    console.debug("TomSelectController: Connected");

    this.loadTomSelectCSS();

    const select = new TomSelect(this.element, {
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

    select.control_input.addEventListener("keydown", function (event) {
      switch (event.key) {
        case "Home":
          event.preventDefault();
          select.control_input.setSelectionRange(0, 0);
          break;

        case "End":
          event.preventDefault();
          const filterValue = select.control_input.value;
          var length = filterValue.length;
          select.control_input.setSelectionRange(length, length);
          break;

        default:
          break;
      }
    });
  }

  disconnect() {
    console.debug("TomSelectController: Disconnected");
    if (this.element.tomselect) {
      this.element.tomselect.destroy();
    }
  }

  loadTomSelectCSS() {
    const cssId = "tom-select-default-css";
    if (!document.getElementById(cssId)) {
      const link = document.createElement("link");
      link.id = cssId;
      link.rel = "stylesheet";
      link.href =
        "https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/css/tom-select.default.css";
      document.head.insertBefore(link, document.head.firstChild);
    }
  }
}
