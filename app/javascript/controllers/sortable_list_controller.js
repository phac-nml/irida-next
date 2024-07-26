import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs";

export default class extends Controller {
  static values = { groupName: String };

  connect() {
    this.sortable = new Sortable(this.element, {
      group: this.groupNameValue,
      animation: 100,
      ghostClass: 'dark:bg-slate-600'
    })
  }
}
