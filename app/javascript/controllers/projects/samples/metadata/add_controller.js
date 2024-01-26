import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["metadataToAdd"]
  addField() {
    const inputFields = document.getElementsByClassName('inputField')
    const lastInputField = inputFields[inputFields.length - 1]
    const nextFieldId = parseInt(lastInputField.id.split('-')[2]) + 1
    const newField =
      `<div id="field_label_${nextFieldId}" class="text-slate-700 dark:text-slate-400 text-sm">
    Field ${nextFieldId + 1}:
    </div>

    <div id='input-field-${nextFieldId}' class="flex space-x-2 mb-2 inputField">
      <div class="relative z-0 w-full group">
      <input type="text" name="key_${nextFieldId}" id="key_${nextFieldId}" class="block py-2.5 px-0 w-full text-sm text-gray-900 bg-transparent border-0 border-b-2 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-primary-500 focus:outline-none focus:ring-0 focus:border-primary-500 peer" placeholder=" "  />
      <label for="key_${nextFieldId}" class="peer-focus:font-medium absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-6 scale-75 top-3 -z-10 origin-[0] peer-focus:start-0 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto peer-focus:text-primary-500 peer-focus:dark:text-primary-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-6">Key</label>

    </div>
    <div class="relative z-0 w-full group">
      <input type="text" name="value_${nextFieldId}" id="value_${nextFieldId}" class="block py-2.5 px-0 w-full text-sm text-gray-900 bg-transparent border-0 border-b-2 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-primary-500 focus:outline-none focus:ring-0 focus:border-primary-500 peer" placeholder=" " />
      <label for="value_${nextFieldId}" class="peer-focus:font-medium absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-6 scale-75 top-3 -z-10 origin-[0] peer-focus:start-0 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto peer-focus:text-primary-500 peer-focus:dark:text-primary-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-6">Value</label>
    </div>
    <button type="button" data-action="projects--samples--metadata--add#removeField" class="ml-auto bg-white text-slate-400 hover:text-slate-900 rounded-lg focus:ring-2 focus:ring-slate-300 p-1.5 hover:bg-slate-100 inline-flex items-center justify-center h-8 w-8 dark:text-slate-500 dark:hover:text-white dark:bg-slate-800 dark:hover:bg-slate-700" data-dismiss-target="#toast-success" aria-label="Close">
      <span class="h-5 w-5 Viral-Icon">
    <svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="Viral-Icon__Svg icon-x_mark" focusable="false">
  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
</svg>

</span>
    </button>`
    lastInputField.insertAdjacentHTML("afterend", newField)
  }

  removeField() {
    console.log('hello remove')
    console.log(document.getElementsByTagName('form'))
    console.log(this.metadataToAddTarget)
  }

  buildMetadata() {
    const inputRows = document.getElementsByClassName('inputField')
    const firstInputRow = parseInt(inputRows[0].id.split('-')[2])
    const lastInputRow = parseInt(inputRows[inputRows.length - 1].id.split('-')[2])
    for (let i = firstInputRow; i < lastInputRow + 1; i++) {

      let metadata_field = document.getElementById(`key_${i}`)
      let value = document.getElementById(`value_${i}`)
      if (metadata_field.value && value.value) {
        let metadataField = `<input type='hidden' name="sample[metadata][${metadata_field.value}]" value="${value.value}">`
        this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataField)
      }
      metadata_field.name = ''
      value.name = ''
    }
  }
}
