/**
 * Turbo State Preservation Mixin
 *
 * Provides functionality to preserve and restore component state across Turbo morphs.
 * This mixin helps Stimulus controllers maintain their state when Turbo morphs the page.
 *
 * Handles three key Turbo events:
 * - turbo:before-render: Save state and mark elements as permanent
 * - turbo:before-morph-element: Preserve element state during morphing
 * - turbo:render: Restore state after morph completes
 *
 * @module TurboStatePreservation
 *
 * @example Basic Usage
 * import TurboStatePreservation from "./concerns/turbo_state_preservation";
 *
 * export default class extends Controller {
 *   connect() {
 *     this.turboState = new TurboStatePreservation(this, {
 *       getState: () => this.selectedIndex,
 *       restoreState: (index) => this.selectTab(index),
 *       onBeforeRender: () => this.markPermanentElements(),
 *       onBeforeMorph: (event) => this.preserveElementState(event),
 *       onRender: () => this.cleanupPermanentMarkers(),
 *       settleDelayMs: 50
 *     });
 *     this.turboState.enable();
 *   }
 *
 *   disconnect() {
 *     this.turboState.disable();
 *   }
 * }
 */
export default class TurboStatePreservation {
  /**
   * @typedef {Object} TurboStateConfig
   * @property {Function} getState - Function to retrieve current state
   * @property {Function} restoreState - Function to restore state (receives state as argument)
   * @property {Function} [onBeforeRender] - Optional callback before Turbo renders
   * @property {Function} [onBeforeMorph] - Optional callback before element morphs (receives event)
   * @property {Function} [onRender] - Optional callback after Turbo renders
   * @property {number} [settleDelayMs=50] - Delay in ms to wait for Turbo to settle after render
   */

  /**
   * Creates a new TurboStatePreservation instance
   * @param {Controller} controller - The Stimulus controller instance
   * @param {TurboStateConfig} config - Configuration object
   */
  constructor(controller, config) {
    this.controller = controller;
    this.getState = config.getState;
    this.restoreState = config.restoreState;
    this.onBeforeRender = config.onBeforeRender;
    this.onBeforeMorph = config.onBeforeMorph;
    this.onRender = config.onRender;
    this.settleDelayMs = config.settleDelayMs || 50;

    this.savedState = null;
    this.boundHandlers = {
      beforeRender: null,
      beforeMorph: null,
      render: null
    };
  }

  /**
   * Enables Turbo state preservation by setting up event listeners
   */
  enable() {
    this.boundHandlers.beforeRender = this.#handleBeforeRender.bind(this);
    this.boundHandlers.beforeMorph = this.#handleBeforeMorph.bind(this);
    this.boundHandlers.render = this.#handleRender.bind(this);

    document.addEventListener("turbo:before-render", this.boundHandlers.beforeRender);
    document.addEventListener("turbo:before-morph-element", this.boundHandlers.beforeMorph);
    document.addEventListener("turbo:render", this.boundHandlers.render);
  }

  /**
   * Disables Turbo state preservation by removing event listeners
   */
  disable() {
    if (this.boundHandlers.beforeRender) {
      document.removeEventListener("turbo:before-render", this.boundHandlers.beforeRender);
    }
    if (this.boundHandlers.beforeMorph) {
      document.removeEventListener("turbo:before-morph-element", this.boundHandlers.beforeMorph);
    }
    if (this.boundHandlers.render) {
      document.removeEventListener("turbo:render", this.boundHandlers.render);
    }
  }

  /**
   * Saves the current state before Turbo renders
   * @private
   * @param {CustomEvent} event - The turbo:before-render event
   */
  #handleBeforeRender(event) {
    try {
      this.savedState = this.getState();
      if (this.onBeforeRender) {
        this.onBeforeRender(event);
      }
    } catch (error) {
      console.error("[TurboStatePreservation] Error in before-render:", error);
    }
  }

  /**
   * Handles element morphing
   * @private
   * @param {CustomEvent} event - The turbo:before-morph-element event
   */
  #handleBeforeMorph(event) {
    try {
      if (this.onBeforeMorph) {
        this.onBeforeMorph(event);
      }
    } catch (error) {
      console.error("[TurboStatePreservation] Error in before-morph:", error);
    }
  }

  /**
   * Restores the saved state after Turbo renders
   * @private
   */
  #handleRender() {
    try {
      if (this.onRender) {
        this.onRender();
      }

      if (this.savedState === null) {
        return;
      }

      // Use setTimeout to ensure Turbo has fully settled
      setTimeout(() => {
        if (this.savedState !== null) {
          this.restoreState(this.savedState);
          this.savedState = null;
        }
      }, this.settleDelayMs);
    } catch (error) {
      console.error("[TurboStatePreservation] Error in render:", error);
    }
  }
}
