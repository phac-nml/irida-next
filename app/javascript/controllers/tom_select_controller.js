import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

export default class TomSelectController extends Controller {
  connect() {
    console.debug("TomSelectController: Connected");

    this.loadTomSelectCSS();

    var first_flag, last_flag;
    const select = this.element;
    const tom_select = new TomSelect(select, {
      render: {
        no_results: null,
        optgroup: function (data, escape) {
          const optgroup = document.createElement("div");
          optgroup.className = "optgroup";
          optgroup.role = "group";
          optgroup.setAttribute("aria-labelledby", data.group.value);
          const optgroup_header = document.createElement("div");
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

    tom_select.control_input.addEventListener("keydown", function (event) {
      switch (event.key) {
        case "Down":
        case "ArrowDown":
          if (first_flag) {
            const first_result_id = tom_select.currentResults.items[0].id;
            const first_result = tom_select.getOption(first_result_id);
            tom_select.setActiveOption(first_result);
            first_flag = false;
          }
          var value = tom_select.activeOption.getAttribute("data-value");
          const last_result_id = tom_select.currentResults.items.at(-1).id;
          if (value === last_result_id) {
            first_flag = true;
          } else {
            first_flag = false;
          }
          break;

        case "Up":
        case "ArrowUp":
          if (last_flag) {
            const last_result_id = tom_select.currentResults.items.at(-1).id;
            const last_result = tom_select.getOption(last_result_id);
            tom_select.setActiveOption(last_result);
            last_flag = false;
          }
          var value = tom_select.activeOption.getAttribute("data-value");
          const first_result_id = tom_select.currentResults.items[0].id;
          if (value === first_result_id) {
            last_flag = true;
          } else {
            last_flag = false;
          }
          break;

        case "Home":
          event.preventDefault();
          tom_select.control_input.setSelectionRange(0, 0);
          break;

        case "End":
          event.preventDefault();
          const filterValue = select.control_input.value;
          const length = filterValue.length;
          tom_select.control_input.setSelectionRange(length, length);
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
