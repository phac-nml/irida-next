import { Controller } from "@hotwired/stimulus";

let nextAddFieldId = 1
const fieldText = document.getElementById('field_label_0').innerText.split(" ")[0]
const keyText = document.getElementById('key_label').innerText
const valueText = document.getElementById('value_label').innerText

export default class extends Controller {
  static targets = ["metadataToAdd"]

  addNewField() {
    const newField = this.getField(nextAddFieldId, '', '')
    document.getElementById(`input-field-${nextAddFieldId - 1}`).insertAdjacentHTML("afterend", newField)
    nextAddFieldId += 1
  }

  removeField(event) {
    const fieldIdToDelete = event.target.parentElement.parentElement.id.split("-")[2]
    document.getElementById(`input-field-${fieldIdToDelete}`).remove()
    for (let i = parseInt(fieldIdToDelete) + 1; i < nextAddFieldId; i++) {
      let currentKey = document.getElementById(`key_${i}`).value
      let currentValue = document.getElementById(`value_${i}`).value
      document.getElementById(`input-field-${i}`).remove()
      const replacementField = this.getField((i - 1), currentKey, currentValue)
      document.getElementById(`input-field-${i - 2}`).insertAdjacentHTML("afterend", replacementField)
    }
    nextAddFieldId -= 1
  }

  buildMetadata() {
    for (let i = 0; i < nextAddFieldId; i++) {
      let metadata_field = document.getElementById(`key_${i}`)
      let value = document.getElementById(`value_${i}`)
      if (metadata_field.value && value.value) {
        let metadataField = `<input type='hidden' name="sample[add_fields][${metadata_field.value}]" value="${value.value}">`
        this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataField)
      }
      metadata_field.name = ''
      value.name = ''
    }
  }

  getField(id, key, value) {
    const newField = `<div id='input-field-${id}' class='inputField'>
      <div id="field_label_${id}" class="text-slate-700 dark:text-slate-400 text-sm mb-2">
        ${fieldText} ${id + 1}:
      </div>
      <div class="flex space-x-2 mb-2">
        <div class="relative z-0 w-full group">
        <input type="text" name="key_${id}" id="key_${id}" value="${key}" class="block py-2.5 px-0 w-full text-sm text-gray-900 bg-transparent border-0 border-b-2 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-primary-500 focus:outline-none focus:ring-0 focus:border-primary-500 peer" placeholder=" "  />
        <label for="key_${id}" class="peer-focus:font-medium absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-6 scale-75 top-3 -z-10 origin-[0] peer-focus:start-0 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto peer-focus:text-primary-500 peer-focus:dark:text-primary-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-6">${keyText}</label>
      </div>
      <div class="relative z-0 w-full group">
        <input type="text" name="value_${id}" id="value_${id}" value="${value}" class="block py-2.5 px-0 w-full text-sm text-gray-900 bg-transparent border-0 border-b-2 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-primary-500 focus:outline-none focus:ring-0 focus:border-primary-500 peer" placeholder=" " />
        <label for="value_${id}" class="peer-focus:font-medium absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-6 scale-75 top-3 -z-10 origin-[0] peer-focus:start-0 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto peer-focus:text-primary-500 peer-focus:dark:text-primary-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-6">${valueText}</label>
      </div>
        <button id="delete-field-${id}"  type="button" data-action="projects--samples--metadata--add#removeField" class="ml-auto bg-white text-slate-400 hover:text-slate-900 rounded-lg focus:ring-2 focus:ring-slate-300 p-1.5 hover:bg-slate-100 inline-flex items-center justify-center h-8 w-8 dark:text-slate-500 dark:hover:text-white dark:bg-slate-800 dark:hover:bg-slate-700" aria-label="Close">
          <span class="h-5 w-5 Viral-Icon">
            <svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="Viral-Icon__Svg icon-x_mark" focusable="false">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </span>
        </button>
      </div>`
    return newField
  }
}
