import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["metadataToAdd", "fieldsContainer", "fieldTemplate"]

  connect() {
    this.addField()
    this.addRequired()
  }

  // Add new field and replace the PLACEHOLDER with a current datetime for unique identifier
  addField() {
    let newField = this.fieldTemplateTarget.innerHTML.replace(/PLACEHOLDER/g, new Date().getTime())
    this.fieldsContainerTarget.insertAdjacentHTML("beforeend", newField)
  }

  removeField(event) {
    let needRequired = false
    let allInputFields = document.querySelectorAll('.inputField')

    // Captures if the first field was deleted, we need to assign the new first field required = true
    if (allInputFields[0] == event.target.closest('.inputField')) {
      needRequired = true
    }

    event.target.closest('.inputField').remove()

    // If only one field existed and was deleted, we need to re-add a field and assign required = true
    if (document.querySelectorAll('.inputField').length == 0) {
      this.addField()
      needRequired = true
    }

    if (needRequired) {
      this.addRequired()
    }
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

  // Makes the first create metadata field required for submissions
  addRequired() {
    this.fieldsContainerTarget.querySelectorAll('.keyInput')[0].required = true
    this.fieldsContainerTarget.querySelectorAll('.valueInput')[0].required = true
  }
}
