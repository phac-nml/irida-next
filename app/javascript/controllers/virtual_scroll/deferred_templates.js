export const deferredTemplatesMixin = {
  /**
   * Set up MutationObserver to detect when deferred templates are added to the DOM
   */
  setupDeferredTemplateObserver() {
    if (!this.hasTemplateContainerTarget) return;

    this.deferredObserver = new MutationObserver((mutations) => {
      // Check if any added nodes have data-deferred attribute
      const hasDeferredContent = mutations.some((mutation) =>
        Array.from(mutation.addedNodes).some(
          (node) =>
            node.nodeType === Node.ELEMENT_NODE &&
            node.dataset?.deferred === "true",
        ),
      );

      if (!hasDeferredContent) return;

      const schedule =
        this.lifecycle?.timeout?.bind(this.lifecycle) || setTimeout;

      // Use setTimeout to ensure all mutations are processed
      schedule(() => {
        // Guard against execution after controller disconnect
        if (!this.element?.isConnected) return;
        this.mergeDeferredTemplates();
      }, 0);
    });

    // Observe the template container for child additions
    this.deferredObserver.observe(this.templateContainerTarget, {
      childList: true,
      subtree: false,
    });

    this.lifecycle?.trackObserver?.(this.deferredObserver);
  },

  /**
   * Merge deferred templates into main container and re-render visible cells
   */
  mergeDeferredTemplates() {
    if (!this.hasTemplateContainerTarget) return;

    try {
      // Find all deferred template containers
      const deferredContainers = this.templateContainerTarget.querySelectorAll(
        '[data-deferred="true"]',
      );

      if (deferredContainers.length === 0) return;

      // Merge deferred templates into existing sample containers
      deferredContainers.forEach((deferredContainer) => {
        const sampleId = deferredContainer.dataset.sampleId;
        const mainContainer = this.templateContainerTarget.querySelector(
          `[data-sample-id="${sampleId}"]:not([data-deferred])`,
        );

        if (mainContainer) {
          // Move all template children from deferred to main container
          Array.from(deferredContainer.children).forEach((template) => {
            mainContainer.appendChild(template);
          });

          // Remove deferred container
          deferredContainer.remove();
        }
      });

      // Re-render visible range to replace placeholders with real cells
      this.replaceVisiblePlaceholders();
    } catch (error) {
      // Dispatch error event for monitoring
      this.element.dispatchEvent(
        new CustomEvent("virtual-scroll:error", {
          detail: { error, context: "mergeDeferredTemplates" },
        }),
      );
    }
  },

  /**
   * Replace placeholder cells in visible range with real cells from templates
   */
  replaceVisiblePlaceholders() {
    if (!this.hasBodyTarget) return;

    const rows = this.bodyTarget.querySelectorAll(
      '[data-virtual-scroll-target="row"]',
    );

    rows.forEach((row) => {
      const placeholders = row.querySelectorAll('[data-placeholder="true"]');

      if (placeholders.length === 0) return;

      const sampleId = row.dataset.sampleId;
      const templates = this.templateContainerTarget?.querySelector(
        `[data-sample-id="${sampleId}"]`,
      );

      placeholders.forEach((placeholder) => {
        const field = placeholder.dataset.fieldId;
        if (!field) return;

        const selector = `template[data-field="${CSS.escape(field)}"]`;
        const template = templates?.querySelector(selector);

        if (!template) return; // Still not available

        // Clone real cell from template
        const clonedContent = template.content.cloneNode(true);
        const realCell = clonedContent.firstElementChild;

        if (!realCell) return;

        // Copy attributes from placeholder
        realCell.dataset.virtualizedCell = "true";
        realCell.dataset.fieldId = field;

        // Apply styles from placeholder
        realCell.style.cssText = placeholder.style.cssText;

        // Copy ARIA attributes
        if (placeholder.hasAttribute("aria-colindex")) {
          realCell.setAttribute(
            "aria-colindex",
            placeholder.getAttribute("aria-colindex"),
          );
        }

        // Replace placeholder with real cell
        placeholder.replaceWith(realCell);
      });
    });
  },
};
