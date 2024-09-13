import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
    static targets = ["input"];
    static values = { page: Number };

    toggleMetadata() {
        if (!this.hasInputTarget) {
            const hiddenPageInput = createHiddenInput("page", this.pageValue);
            hiddenPageInput.setAttribute("data-samples-target", "input");
            this.element.appendChild(hiddenPageInput);
        }

        Turbo.navigator.submitForm(this.element);
    }
}
