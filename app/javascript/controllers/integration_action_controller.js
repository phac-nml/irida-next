import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    token: String
  }

  connect() {}

  authorize(event){
    // generate token

    window.opener.postMessage(this.tokenValue, 'http:localhost:8081')
    window.close()
  }
}
