import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { loaded: { type: Boolean, default: false } }

  connect() {
    this.loadedValue = true
  }
}
