import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  scroll() {
    if(this.element.scrollHeight - this.element.scrollTop <= this.element.clientHeight + 1){
      this.submitForm();
    }
  }

  submitForm() {
    const frame =  document.getElementById("list_select_samples_pagination");
    if (frame) {
      const form = frame.querySelector("form");
      form.requestSubmit();
    }
  }
}
