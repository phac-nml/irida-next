import { Controller } from "@hotwired/stimulus"
import { Sortable } from "sortablejs";

export default class extends Controller {
  static values = {
    groupName: String,
    scrollSensitivity: {
      type: Number,
      default: 50,
    },
    scrollSpeed: {
      type: Number,
      default: 8,
    }
  }
  connect() {
    this.sortable = new Sortable(this.element, {
      scroll: true,
      forceFallback: true,
      scrollSensitivity: this.scrollSensitivityValue, // The number of px from div edge where scroll begins
      scrollSpeed: this.scrollSpeedValue,
      bubbleScroll: true,
      group: this.groupNameValue,
      animation: 100
    })
  }
}
