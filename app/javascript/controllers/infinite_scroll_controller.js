import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  connect(){
    console.log("CONNECTED");
    // this.#submitForm();
  }

  scroll() {
    if((this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight) < 1){
      this.#submitForm();
    }
  }

  #submitForm(){
    const frame =  document.getElementById("list_select_samples_pagination");
    const form = frame.querySelector("form");
    form.requestSubmit();
  }
}
