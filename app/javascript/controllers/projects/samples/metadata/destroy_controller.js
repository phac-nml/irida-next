import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["field"];

    static values = {
        storageKey: {
            type: String,
            default: `${location.protocol}//${location.host}${location.pathname}${location.search}`
        },
    };

    connect() {
        const storageValues = JSON.parse(
            sessionStorage.getItem(this.storageKeyValue)
        );
        if (storageValues) {
            for (const storageValue of storageValues) {
                const element = document.createElement("input");
                element.type = "hidden";
                element.name = `sample[metadata][${storageValue}]`;
                element.value = '';
                this.fieldTarget.appendChild(element);
            }
        }
    }

    clear() {
        sessionStorage.removeItem(this.storageKeyValue);
    }
}
