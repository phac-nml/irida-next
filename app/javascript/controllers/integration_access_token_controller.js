import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    token: String,
    target: String,
  }

  connect() {
    setTimeout(() => {
      try {
        if (window.opener && !window.opener.closed) {
          window.opener.postMessage(this.tokenValue, this.targetValue)
        } else {
          console.error('Parent window unavailable')
        }
        window.close()
      } catch (error) {
        console.error('Failed to send token:', error)
      }
    }, 3000)
  }
}
