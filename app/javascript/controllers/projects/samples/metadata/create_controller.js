import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["metadataToAdd", "inputsContainer"]


  connect() {
    // Grabs labels for field manipulation in case of translations
    this.fieldLabel = this.inputsContainerTarget.querySelector('.field-label').innerText.split(" ")[0]

    // Used to create new fields
    this.newFieldTemplate = document.getElementById('wrapper')

    // Assigns required after assigning template without required to newFieldTemplate
    this.inputsContainerTarget.querySelector('.key-input').required = true
    this.inputsContainerTarget.querySelector('.value-input').required = true
  }

  // Add new field with next ID increment
  addNewField() {
    const id = document.getElementsByClassName('input-field').length
    const newFieldWithIds = this.assignFieldIdNumbering(this.newFieldTemplate.cloneNode(true), id)
    this.inputsContainerTarget.insertAdjacentHTML("beforeend", newFieldWithIds.innerHTML)
  }

  // When a field is removed, all fields 'after' will have their "Field #" label and data-field-id reduced by 1.
  removeField(event) {
    const totalInputFields = document.getElementsByClassName('input-field').length

    // If there's only 1 input field, we will clear the inputs rather than delete the field.
    if (totalInputFields == 1) {
      const fieldToClear = event.target.closest('.input-field')
      fieldToClear.querySelector('.key-input').value = ''
      fieldToClear.querySelector('.value-input').value = ''
    } else {
      const fieldToDelete = event.target.closest('.input-field')
      const deleteFieldId = parseInt(fieldToDelete.querySelector(".field-label").innerHTML.split(" ")[1]) - 1
      fieldToDelete.remove()

      let inputFields = document.getElementsByClassName('input-field')
      for (let i = deleteFieldId; i < inputFields.length; i++) {
        this.assignFieldIdNumbering(inputFields[i], i)
      }
    }

  }

  // Metadata is constructed and validated before submission to the backend. Any fields that has key and/or value blank,
  // we ignore and do not submit those fields.
  buildMetadata() {
    const inputFields = document.getElementsByClassName('input-field')
    for (let input of inputFields) {
      let metadata_field = input.querySelector('.key-input')
      let value = input.querySelector('.value-input')
      if (metadata_field.value && value.value) {
        let metadataInput = `<input type='hidden' name="sample[create_fields][${metadata_field.value}]" value="${value.value}">`
        this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataInput)
      }
      metadata_field.name = ''
      value.name = ''
    }
  }

  // Used by add and remove fields to relabel all ids/names/fors for continuous numbering
  assignFieldIdNumbering(field, id) {
    field.querySelector(".field-label").innerText = `${this.fieldLabel} ${id + 1}:`
    field.querySelector('.key-input').id = `key-${id}`
    field.querySelector('.key-input').name = `key-${id}`
    field.querySelector('.key-label').htmlFor = `key-${id}`
    field.querySelector('.value-input').id = `value-${id}`
    field.querySelector('.value-input').name = `value-${id}`
    field.querySelector('.value-label').htmlFor = `value-${id}`
    return field
  }
}
