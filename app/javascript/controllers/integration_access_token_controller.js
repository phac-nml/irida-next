import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    token: String,
    urls: Array,
    target: String,
  }

  connect() {
    setTimeout(() => {
      window.opener.postMessage(this.tokenValue, this.targetValue)
      window.close()
    }, 3000)
  }
}
