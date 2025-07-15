import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    token: String
  }

  connect() {
    console.log(this.tokenValue)
    setTimeout(() => {
      window.opener.postMessage(this.tokenValue, 'http:localhost:8081')
      window.close()
    }, 3000)
  }
}
