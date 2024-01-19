import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

    addField() {
        const inputFields = document.getElementsByClassName('inputField')
        const lastInputField = inputFields[inputFields.length - 1]
        const nextFieldId = parseInt(lastInputField.id.split('-')[2]) + 1

        const newField =
            `<div id="input-field-${nextFieldId}" class="flex space-x-2 mb-2 inputField">
                <input type="text" id="sample_key_${nextFieldId}">
                <input type="text" id="sample_value_${nextFieldId}">
            </div>`
        lastInputField.insertAdjacentHTML("afterend", newField)
    }

    buildMetadata() {
        const inputRows = document.getElementsByClassName('inputField')
        const firstInputRow = parseInt(inputRows[0].id.split('-')[2])
        const lastInputRow = parseInt(inputRows[inputRows.length - 1].id.split('-')[2])

        let metadata = []

        for (let i = firstInputRow; i < lastInputRow + 1; i++) {

            let metadata_field = document.getElementById(`sample_key_${i}`).value
            let value = document.getElementById(`sample_value_${i}`).value

            if (metadata_field && value) {
                let metadata_to_add = {}
                metadata_to_add[metadata_field] = value
                metadata.push(metadata_to_add)
            }
        }
        document.getElementById('sample_metadata').value = JSON.stringify(metadata)
    }
}
