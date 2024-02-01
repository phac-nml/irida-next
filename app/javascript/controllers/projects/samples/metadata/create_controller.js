import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["metadataToAdd", "inputsContainer"]


  connect() {
    // Grabs labels for field manipulation in case of translations
    this.fieldLabel = this.inputsContainerTarget.querySelector('#field-label').innerText.split(" ")[0]
    this.keyLabel = this.inputsContainerTarget.querySelector('#key-label').innerText
    this.valueLabel = this.inputsContainerTarget.querySelector('#value-label').innerText
  }

  // Add new field with next ID increment
  addNewField() {
    const id = document.getElementsByClassName('inputField').length
    const newField =
      `<div class='inputField' data-field-id="${id}">
        <div class="fieldLabel text-slate-700 dark:text-slate-400 text-sm mb-2">
          ${this.fieldLabel} ${id + 1}:
        </div>
        <div class="flex space-x-2 mb-2">
          <div class="relative z-0 w-full group">
            <input type="text" name="key-${id}" class="keyInput block py-2.5 px-0 w-full text-sm text-slate-900 bg-transparent border-0 border-b-2 border-slate-300 appearance-none dark:text-white dark:border-slate-600 dark:focus:border-primary-500 focus:outline-none focus:ring-0 focus:border-primary-500 peer" placeholder=" "  />
            <label for="key-${id}" class="peer-focus:font-medium absolute text-sm text-slate-500 dark:text-slate-400 duration-300 transform -translate-y-6 scale-75 top-3 -z-10 origin-[0] peer-focus:start-0 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto peer-focus:text-primary-500 peer-focus:dark:text-primary-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-6">${this.keyLabel}</label>
          </div>
          <div class="relative z-0 w-full group">
            <input type="text" name="value-${id}" class="valueInput block py-2.5 px-0 w-full text-sm text-slate-900 bg-transparent border-0 border-b-2 border-slate-300 appearance-none dark:text-white dark:border-slate-600 dark:focus:border-primary-500 focus:outline-none focus:ring-0 focus:border-primary-500 peer" placeholder=" " />
            <label for="value-${id}" class="peer-focus:font-medium absolute text-sm text-slate-500 dark:text-slate-400 duration-300 transform -translate-y-6 scale-75 top-3 -z-10 origin-[0] peer-focus:start-0 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto peer-focus:text-primary-500 peer-focus:dark:text-primary-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-6">${this.valueLabel}</label>
          </div>
          <button type="button" data-action="projects--samples--metadata--create#removeField" class="ml-auto bg-white text-slate-400 hover:text-slate-900 rounded-lg focus:ring-2 focus:ring-slate-300 p-1.5 hover:bg-slate-100 inline-flex items-center justify-center h-8 w-8 dark:text-slate-500 dark:hover:text-white dark:bg-slate-800 dark:hover:bg-slate-700" aria-label="Remove field">
            <span class="h-5 w-5 Viral-Icon pointer-events-none">
              <svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="Viral-Icon__Svg icon-x_mark pointer-events-none" focusable="false">
                <path class="pointer-events-none" stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </span>
          </button>
        </div>
      </div>`
    this.inputsContainerTarget.insertAdjacentHTML("beforeend", newField)
  }

  // When a field is removed, all fields 'after' will have their "Field #" label and data-field-id reduced by 1.
  removeField(event) {
    const fieldToDelete = event.target.closest('.inputField')
    const inputId = parseInt(fieldToDelete.dataset.fieldId)
    fieldToDelete.remove()
    const inputFields = document.getElementsByClassName('inputField')
    for (let i = inputId; i < inputFields.length; i++) {
      inputFields[i].querySelector(".fieldLabel").innerText = `${this.fieldLabel} ${i + 1}:`
      inputFields[i].dataset.fieldId = i
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
        let metadataFieldInput = `<input type='hidden' name="sample[add_fields][${metadata_field.value}]" value="${value.value}">`
        this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataFieldInput)
      }
      metadata_field.name = ''
      value.name = ''
    }
  }
}
