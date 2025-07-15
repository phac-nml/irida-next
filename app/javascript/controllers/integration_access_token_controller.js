import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    token: String
  }

  connect() {
    const referrer = document.referrer
    const allow_list = ['http://localhost:8081/'] // TODO: make this configurable
    if (allow_list.includes(referrer)) {
      setTimeout(() => {
        window.opener.postMessage(this.tokenValue, referrer)
        window.close()
      }, 3000)
    } else {
      console.log("Requesting integration referrer is not on approve list")
      // TODO: make this an error that the user can see
      // TODO: maybe have this done in the turbo streams
    }
  }
}
