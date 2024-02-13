import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["metadataToAdd", "fieldsContainer", "fieldTemplate"]

  connect() {
    this.addField()
  }

  // Add new field and replace the PLACEHOLDER with a current datetime for unique identifier
  addField() {
    const currentTime = new Date().getTime()
    let newField = this.fieldTemplateTarget.innerHTML.replace(/PLACEHOLDER/g, currentTime)
    this.fieldsContainerTarget.insertAdjacentHTML("beforeend", newField)

    document.getElementById(`key[${currentTime}]`).focus()
  }

  removeField(event) {
    event.target.closest('.inputField').remove()

    // If only one field existed and was deleted, we re-add a new field
    if (document.querySelectorAll('.inputField').length == 0) {
      this.addField()
    }
  }

  // Metadata is constructed and validated before submission to the backend. Any fields that has key and/or value blank,
  // we ignore and do not submit those fields.
  buildMetadata() {
    const inputFields = document.querySelectorAll('.inputField')
    for (let input of inputFields) {
      let metadata_field = input.querySelector('.keyInput')
      let value = input.querySelector('.valueInput')
      let metadataInput = `<input type='hidden' name="sample[create_fields][${metadata_field.value}]" value="${value.value}">`
      this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataInput)
      metadata_field.name = ''
      value.name = ''
    }
  }
}
