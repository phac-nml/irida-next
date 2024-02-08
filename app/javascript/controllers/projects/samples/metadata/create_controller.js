import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["metadataToAdd", "inputsContainer", "wrapper"]


  connect() {
    // Grabs labels for field manipulation in case of translations
    this.fieldLabel = this.wrapperTarget.querySelector('.fieldLabel').innerText.split(" ")[0]

    // Used to create new fields
    this.newFieldTemplate = this.wrapperTarget.cloneNode(true)

    // Assigns required after cloning the template
    this.wrapperTarget.querySelector('.keyInput').required = true
    this.wrapperTarget.querySelector('.valueInput').required = true
  }

  // Add new field with next ID increment
  addField() {
    const id = document.getElementsByClassName('inputField').length
    let newFieldWithIds = this.assignFieldIds(this.newFieldTemplate, id)
    this.inputsContainerTarget.insertAdjacentHTML("beforeend", newFieldWithIds.innerHTML)
  }

  // When a field is removed, all fields 'after' will have their "Field #" and identifiers reduced by 1
  // to have continuous numbering in the field list.
  removeField(event) {
    let inputFields = document.getElementsByClassName('inputField')
    let fieldToDelete = event.target.closest('.inputField')
    // If there's only 1 input field, we will clear the inputs rather than delete the field.
    if (inputFields.length == 1) {
      fieldToDelete.querySelector('.keyInput').value = ''
      fieldToDelete.querySelector('.valueInput').value = ''
    } else {
      const deleteFieldId = parseInt(fieldToDelete.id.slice(-1))
      fieldToDelete.remove()

      for (let i = deleteFieldId; i < inputFields.length; i++) {
        this.assignFieldIds(inputFields[i], i)
      }
    }
  }

  // Used by add and remove fields to relabel all ids/names/fors for continuous numbering
  assignFieldIds(field, id) {
    // addField will have an additional wrapper which has no id and will require a query
    field.id ? field.id = `inputField${id}` : field.querySelector(".inputField").id = `inputField${id}`
    field.querySelector(".fieldLabel").innerText = `${this.fieldLabel} ${id + 1}:`

    let keyInput = field.querySelector('.keyInput')
    keyInput.id = `key${id}`
    keyInput.name = `key${id}`
    field.querySelector('.keyLabel').htmlFor = `key${id}`

    let valueInput = field.querySelector('.valueInput')
    valueInput.id = `value${id}`
    valueInput.name = `value${id}`
    field.querySelector('.valueLabel').htmlFor = `value${id}`
    return field
  }

  // Metadata is constructed and validated before submission to the backend. Any fields that has key and/or value blank,
  // we ignore and do not submit those fields.
  buildMetadata() {
    const inputFields = document.getElementsByClassName('inputField')
    for (let input of inputFields) {
      let metadata_field = input.querySelector('.keyInput')
      let value = input.querySelector('.valueInput')
      if (metadata_field.value && value.value) {
        let metadataInput = `<input type='hidden' name="sample[create_fields][${metadata_field.value}]" value="${value.value}">`
        this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataInput)
      }
      metadata_field.name = ''
      value.name = ''
    }
  }
}
