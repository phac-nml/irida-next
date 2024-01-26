import { Controller } from "@hotwired/stimulus";

//creates hidden fields within a form for selected files
export default class extends Controller {
    static targets = ["metadataEdit"];

    edit(event) {
        // The metadata key and value fields are structured like "#{metadata[:key]}_key" or "#{metadata[:key]}_value"
        // so we know which metadata key to edit, and whether its a key or value we're updating.
        const splitType = event.target.id.split('_')
        const type = splitType[splitType.length - 1]
        const old_key = splitType[splitType.length - 2]

        // Change the hidden inputs's name that will be submitted so we know in the backend via hash key if we're
        // editing a key or value, and which metadata key.
        if (type == 'key') {
            this.metadataEditTarget.name = `sample[metadata][key_${old_key}]`
        } else {
            this.metadataEditTarget.name = `sample[metadata][value_${old_key}]`
        }
        this.metadataEditTarget.value = event.target.value

        // Remove all metadata input fields from the form so they don't submit to the controller
        const metadata_form_fields = document.getElementsByClassName('metadata-input')
        for (let i = 0; i < metadata_form_fields.length; i++) {
            metadata_form_fields[i].name = ''
        }
        this.element.requestSubmit()
    }
}
