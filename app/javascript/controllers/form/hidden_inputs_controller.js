import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
    static outlets = ["selection"];
    static values = {
        fieldName: String,
    };

    connect() {
        this.allIds = this.selectionOutlet.getStoredItems();
        this.#appendHiddenInputs();
    }

    clearSelection() {
        this.selectionOutlet.clear();
    }

    #appendHiddenInputs() {
        const fragment = document.createDocumentFragment();
        for (const id of this.allIds) {
            fragment.appendChild(createHiddenInput(this.fieldNameValue, id));
        }
        this.element.appendChild(fragment);
    }
}
