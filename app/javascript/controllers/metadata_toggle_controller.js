import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
    static values = { page: Number };

    submit() {
        const hiddenPageInput = createHiddenInput("page", this.pageValue);
        this.element.appendChild(hiddenPageInput);
        Turbo.navigator.submitForm(this.element);
    }
}
