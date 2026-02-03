import { Controller } from "@hotwired/stimulus";
import {
  arrow,
  autoUpdate,
  computePosition,
  flip,
  offset,
  shift,
} from "@floating-ui/dom";

/**
 * Shared registry for global event delegation.
 * Single set of document-level listeners for all tooltip instances.
 */
class TooltipRegistry {
  #controllers = new Set();
  #abortController = null;

  register(controller) {
    this.#controllers.add(controller);
    if (!this.#abortController) {
      this.#setupGlobalListeners();
    }
  }

  unregister(controller) {
    this.#controllers.delete(controller);
    if (this.#controllers.size === 0) {
      this.#teardownGlobalListeners();
    }
  }

  hideAllExcept(activeController) {
    this.#controllers.forEach((c) => {
      if (c !== activeController) {
        c.hide();
      }
    });
  }

  #setupGlobalListeners() {
    this.#abortController = new AbortController();
    const { signal } = this.#abortController;

    document.addEventListener(
      "keydown",
      (event) => {
        if (event.key === "Escape") {
          this.#controllers.forEach((c) => c.handleEscape(event));
        }
      },
      { signal },
    );

    document.addEventListener(
      "touchstart",
      (event) => {
        this.#controllers.forEach((c) => c.handleTouchOutside(event));
      },
      { signal, passive: true },
    );
  }

  #teardownGlobalListeners() {
    this.#abortController?.abort();
    this.#abortController = null;
  }
}

const tooltipRegistry = new TooltipRegistry();

/**
 * Pathogen::Tooltip Stimulus Controller
 *
 * Viewport-aware tooltip positioning powered by Floating UI.
 * Uses computePosition with offset/flip/shift/arrow middleware plus autoUpdate
 * for scroll/resize adaptation.
 *
 * ## Features
 * - Collision-aware positioning with configurable middleware
 * - Optional arrow element with automatic placement
 * - Configurable autoUpdate for performance tuning
 * - Touch device support with tap-to-show/tap-to-navigate
 * - Respects prefers-reduced-motion
 * - Portals tooltip to body to escape CSS containment contexts
 *
 * ## Accessibility (W3C ARIA APG Tooltip Pattern)
 * - Tooltip remains open over trigger OR tooltip
 * - Escape key dismissal
 * - Focus loss dismissal
 * - Touch outside dismissal
 * - Requires aria-describedby from trigger to tooltip
 * - Validates keyboard accessibility
 * - Prevents simultaneous tooltips
 *
 * @example Basic usage
 * <div data-controller="pathogen--tooltip">
 *   <button data-pathogen--tooltip-target="trigger"
 *           aria-describedby="tip-1">Hover me</button>
 *   <div id="tip-1" role="tooltip"
 *        data-pathogen--tooltip-target="tooltip">
 *     Tooltip content
 *   </div>
 * </div>
 *
 * @example With arrow
 * <div data-controller="pathogen--tooltip">
 *   <button data-pathogen--tooltip-target="trigger"
 *           aria-describedby="tip-2">With arrow</button>
 *   <div id="tip-2" role="tooltip"
 *        data-pathogen--tooltip-target="tooltip">
 *     Content
 *     <div data-pathogen--tooltip-target="arrow"></div>
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["trigger", "tooltip"];

  static values = {
    spacing: { type: Number, default: 8 },
    viewportPadding: { type: Number, default: 8 },
    touchDismissDelay: { type: Number, default: 3000 },
    hideDelay: { type: Number, default: 300 },
    // autoUpdate options
    ancestorScroll: { type: Boolean, default: true },
    ancestorResize: { type: Boolean, default: true },
    elementResize: { type: Boolean, default: true },
    layoutShift: { type: Boolean, default: true },
    animationFrame: { type: Boolean, default: false },
  };

  // Private fields - store direct references since tooltip is portaled to body
  #cleanupAutoUpdate = null;
  #touchDismissTimeout = null;
  #hideTimeout = null;
  #touchPrimed = false;
  #touchStarted = false;
  #escapeDismissed = false;
  #prefersReducedMotion = false;
  #abortController = new AbortController();
  #originalParent = null;
  #tooltipElement = null;
  #triggerElement = null;
  #arrowElement = null;

  connect() {
    this.element.dataset.controllerConnected = "true";

    this.#prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;

    tooltipRegistry.register(this);
  }

  disconnect() {
    // Ensure portaled tooltip is fully hidden before teardown to avoid lingering visibility
    this.hide();
    this.#clearHideTimeout();
    this.#stopAutoUpdate();
    this.#clearTouchTimeout();
    this.#abortController?.abort();
    tooltipRegistry.unregister(this);

    // Return tooltip to original parent if portaled
    if (
      this.#tooltipElement?.parentElement === document.body &&
      this.#originalParent
    ) {
      this.#originalParent.appendChild(this.#tooltipElement);
    }
  }

  triggerTargetConnected(element) {
    this.#triggerElement = element;
    this.#validateAriaDescribedBy(element);
    this.#validateKeyboardAccessibility(element);

    const { signal } = this.#abortController;

    element.addEventListener(
      "mouseenter",
      () => {
        this.#clearHideTimeout();
        this.show();
      },
      { signal },
    );

    element.addEventListener(
      "mouseleave",
      () => {
        this.#scheduleHide();
      },
      { signal },
    );

    element.addEventListener("focusin", () => this.show(), { signal });
    element.addEventListener("focusout", () => this.hide(), { signal });
    element.addEventListener("touchstart", (e) => this.#handleTouchStart(e), {
      signal,
      passive: true,
    });
    element.addEventListener("click", (e) => this.#handleClick(e), { signal });
  }

  tooltipTargetConnected(element) {
    // Store direct reference before portaling (Stimulus targets won't work after)
    this.#tooltipElement = element;

    // Find and store arrow element (nested inside tooltip, won't work as Stimulus target after portal)
    this.#arrowElement = element.querySelector(
      '[data-pathogen--tooltip-target="arrow"]',
    );

    const { signal } = this.#abortController;

    element.addEventListener(
      "mouseenter",
      () => {
        this.#clearHideTimeout();
      },
      { signal },
    );
    element.addEventListener(
      "mouseleave",
      () => {
        this.#scheduleHide();
      },
      { signal },
    );

    // Portal tooltip to body to escape CSS containment contexts
    // (container queries, transforms, filters create containing blocks
    // that break position: fixed). Skip when inside a dialog so the tooltip
    // remains in the top layer with the dialog content.
    if (!element.closest("dialog")) {
      this.#portalToBody(element);
    }
  }

  /**
   * Shows the tooltip with positioning and optional animation.
   */
  show() {
    if (!this.#tooltipElement || this.#escapeDismissed) return;

    this.#hideOtherTooltips();

    this.#tooltipElement.setAttribute("aria-hidden", "false");

    if (this.#prefersReducedMotion) {
      this.#tooltipElement.classList.remove("invisible", "opacity-0");
      this.#tooltipElement.classList.add("visible", "opacity-100");
    } else {
      this.#tooltipElement.classList.remove("scale-90", "invisible");
      this.#tooltipElement.classList.add("scale-100", "visible");
      this.#tooltipElement.classList.remove("opacity-0");
      this.#tooltipElement.classList.add("opacity-100");
    }

    this.#startAutoUpdate();
    this.#positionTooltip();
  }

  /**
   * Hides the tooltip with optional animation.
   */
  hide() {
    if (!this.#tooltipElement) return;

    this.#clearTouchTimeout();
    this.#clearHideTimeout();
    this.#touchPrimed = false;

    this.#tooltipElement.setAttribute("aria-hidden", "true");

    if (this.#prefersReducedMotion) {
      this.#tooltipElement.classList.remove("visible", "opacity-100");
      this.#tooltipElement.classList.add("invisible", "opacity-0");
    } else {
      this.#tooltipElement.classList.remove(
        "opacity-100",
        "scale-100",
        "visible",
      );
      this.#tooltipElement.classList.add("opacity-0", "scale-90", "invisible");
    }

    this.#stopAutoUpdate();
  }

  /**
   * Handles Escape key dismissal (called by registry).
   */
  handleEscape(_event) {
    if (!this.#tooltipElement || !this.#isVisible()) return;

    this.#escapeDismissed = true;
    this.hide();

    if (this.#triggerElement) {
      this.#triggerElement.focus();
    }

    setTimeout(() => {
      this.#escapeDismissed = false;
    }, 100);
  }

  /**
   * Handles touch outside dismissal (called by registry).
   */
  handleTouchOutside(event) {
    if (!this.#tooltipElement || !this.#triggerElement || !this.#isVisible())
      return;

    const target = event.target;
    const isOutside =
      !this.#tooltipElement.contains(target) &&
      !this.#triggerElement.contains(target) &&
      !this.element.contains(target);

    if (isOutside) {
      this.hide();
    }
  }

  // Private methods

  #handleTouchStart(_event) {
    if (!this.#tooltipElement || !this.#triggerElement) return;
    this.#touchStarted = true;
  }

  #handleClick(event) {
    if (!this.#tooltipElement || !this.#triggerElement || !this.#touchStarted)
      return;

    this.#touchStarted = false;

    if (this.#isVisible() && this.#touchPrimed) {
      this.#touchPrimed = false;
      this.hide();
    } else {
      this.#touchPrimed = true;
      event.preventDefault();
      this.show();
      this.#startTouchDismissTimer();
    }
  }

  #positionTooltip() {
    if (!this.#triggerElement || !this.#tooltipElement) return;

    const placement = this.#tooltipElement.dataset.placement || "top";
    const middleware = [
      offset(this.spacingValue),
      flip({ padding: this.viewportPaddingValue }),
      shift({ padding: this.viewportPaddingValue }),
    ];

    if (this.#arrowElement) {
      middleware.push(arrow({ element: this.#arrowElement }));
    }

    computePosition(this.#triggerElement, this.#tooltipElement, {
      placement,
      strategy: "fixed",
      middleware,
    })
      .then(({ x, y, placement: finalPlacement, middlewareData }) => {
        this.#tooltipElement.dataset.currentPlacement = finalPlacement;

        Object.assign(this.#tooltipElement.style, {
          top: `${y}px`,
          left: `${x}px`,
        });

        if (this.#arrowElement && middlewareData.arrow) {
          this.#positionArrow(finalPlacement, middlewareData.arrow);
        }
      })
      .catch(() => {
        Object.assign(this.#tooltipElement.style, {
          top: "-9999px",
          left: "-9999px",
        });
      });
  }

  #positionArrow(placement, arrowData) {
    const { x: arrowX, y: arrowY } = arrowData;

    const staticSide = {
      top: "bottom",
      right: "left",
      bottom: "top",
      left: "right",
    }[placement.split("-")[0]];

    Object.assign(this.#arrowElement.style, {
      left: arrowX != null ? `${arrowX}px` : "",
      top: arrowY != null ? `${arrowY}px` : "",
      right: "",
      bottom: "",
      [staticSide]: "-4px",
    });
  }

  #startAutoUpdate() {
    if (!this.#triggerElement || !this.#tooltipElement) return;
    if (this.#cleanupAutoUpdate) return;

    this.#cleanupAutoUpdate = autoUpdate(
      this.#triggerElement,
      this.#tooltipElement,
      () => this.#positionTooltip(),
      {
        ancestorScroll: this.ancestorScrollValue,
        ancestorResize: this.ancestorResizeValue,
        elementResize: this.elementResizeValue,
        layoutShift: this.layoutShiftValue,
        animationFrame: this.animationFrameValue,
      },
    );
  }

  #stopAutoUpdate() {
    this.#cleanupAutoUpdate?.();
    this.#cleanupAutoUpdate = null;
  }

  #startTouchDismissTimer() {
    this.#clearTouchTimeout();

    this.#touchDismissTimeout = setTimeout(() => {
      this.hide();
      this.#touchPrimed = false;
      this.#touchDismissTimeout = null;
    }, this.touchDismissDelayValue);
  }

  #clearTouchTimeout() {
    if (this.#touchDismissTimeout) {
      clearTimeout(this.#touchDismissTimeout);
      this.#touchDismissTimeout = null;
    }
  }

  #scheduleHide() {
    this.#clearHideTimeout();
    this.#hideTimeout = setTimeout(() => {
      this.hide();
    }, this.hideDelayValue);
  }

  #clearHideTimeout() {
    if (this.#hideTimeout) {
      clearTimeout(this.#hideTimeout);
      this.#hideTimeout = null;
    }
  }

  #portalToBody(tooltipElement) {
    // Store original parent for cleanup
    this.#originalParent = tooltipElement.parentElement;

    // Move tooltip to body to escape CSS containment contexts
    // (container queries, transforms, filters create containing blocks
    // that break position: fixed)
    document.body.appendChild(tooltipElement);
  }

  #isVisible() {
    return (
      this.#tooltipElement &&
      this.#tooltipElement.classList.contains("opacity-100") &&
      this.#tooltipElement.classList.contains("visible")
    );
  }

  #hideOtherTooltips() {
    tooltipRegistry.hideAllExcept(this);
  }

  #validateAriaDescribedBy(triggerElement) {
    if (!this.#tooltipElement) return;

    const tooltipId = this.#tooltipElement.id;
    if (!tooltipId) {
      console.error(
        "[Pathogen::Tooltip] Tooltip element must have an id attribute.",
      );
      return;
    }

    const describedBy = triggerElement.getAttribute("aria-describedby");
    if (!describedBy) {
      triggerElement.setAttribute("aria-describedby", tooltipId);
      console.error(
        `[Pathogen::Tooltip] Trigger missing aria-describedby="${tooltipId}".`,
      );
      return;
    }

    const ids = describedBy.split(/\s+/).filter(Boolean);
    if (!ids.includes(tooltipId)) {
      triggerElement.setAttribute(
        "aria-describedby",
        `${describedBy} ${tooltipId}`.trim(),
      );
      console.error(
        `[Pathogen::Tooltip] aria-describedby must include "${tooltipId}".`,
      );
    }
  }

  #validateKeyboardAccessibility(triggerElement) {
    const focusable = triggerElement.matches(
      'a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])',
    );

    if (!focusable) {
      console.warn(
        `[Pathogen::Tooltip] Trigger not keyboard-focusable. Add tabindex="0".`,
      );
    }
  }
}
