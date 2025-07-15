import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    token: String,
    urls: Array
  }

  connect() {
    const referrer = document.referrer
    if (this.urlsValue.includes(referrer)) {
      setTimeout(() => {
        window.opener.postMessage(this.tokenValue, referrer)
        window.close()
      }, 3000)
    }
  }
}
