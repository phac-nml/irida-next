import { Controller } from "@hotwired/stimulus";

/**
 * 🎮 Controls the enabled/disabled state of an action button.
 *
 * This controller disables the target button element if a specified 'required'
 * count is not met. It's useful for scenarios where an action should only
 * be available after a certain number of items are selected or conditions are fulfilled.
 *
 * @property {number} requiredValue - The minimum count required to enable the button. Defaults to 0.
 */
export default class extends Controller {
  static values = {
    /**
     * 🔢 The minimum number of items/conditions required for the button to be enabled.
     * If the current count is less than this value, the button will be disabled.
     * @type {number}
     * @default 0
     */
    required: { type: Number, default: 0 },
  };

  /**
   * 🔗 Called automatically when the controller is connected to the DOM.
   * Initializes the button's disabled state.
   */
  connect() {
    this.idempotentConnect();
  }

  /**
   * 🔄 Idempotent connection logic to set the initial disabled state of the button.
   * This method can be called multiple times without side effects beyond the initial setup.
   */
  idempotentConnect() {
    // Initially, check if the button should be disabled based on the requiredValue.
    // Assumes a count of 0 if no specific count is provided at initialization.
    this.setDisabled(0);
  }

  /**
   * ⚙️ Sets the disabled state of the button element.
   *
   * This method compares the provided count against the `requiredValue`.
   * If `requiredValue` is greater than the `count`, the button is disabled; otherwise, it's enabled.
   *
   * @param {number} [count=0] - The current count to compare against `requiredValue`. Defaults to 0.
   */
  setDisabled(count = 0) {
    if (this.requiredValue > count) {
      this.element.disabled = true;
    } else {
      this.element.disabled = false;
    }
  }
}
