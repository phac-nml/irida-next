import { Controller } from "@hotwired/stimulus";
import { announce } from "utilities/live_region";

export default class extends Controller {
  static targets = [
    "rowSelection",
    "selectPage",
    "selectPageStatus",
    "selected",
    "status",
    "limitAlert",
    "limitAlertMessage",
  ];
  static outlets = ["action-button"];

  static values = {
    storageKey: {
      type: String,
    },
    total: Number,
    countMessage: String,
    selectPageNone: String,
    selectPageSome: String,
    selectPageAll: String,
    maxSelection: Number,
    limitMessage: String,
  };

  #lastActiveCheckbox;
  /**
   * Called when the Stimulus controller connects to the DOM.
   * - Marks the element as connected for debugging/automation.
   * - Restores any stored selection from sessionStorage.
   * - Listens for Turbo "morph" events to re-sync UI after partial updates.
   */
  connect() {
    this.element.setAttribute("data-controller-connected", "true");

    this.boundOnMorph = this.onMorph.bind(this);
    this.boundOnTurboRender = this.onTurboRender.bind(this);
    this.boundOnViralAlertDismissed =
      this.#handleViralAlertDismissed.bind(this);

    this.#initializeSelectionState();
    this.#applyLimitAlertDismissedState();

    document.addEventListener("turbo:morph", this.boundOnMorph);
    document.addEventListener("turbo:render", this.boundOnTurboRender);
    document.addEventListener(
      "viral--alert:dismissed",
      this.boundOnViralAlertDismissed,
    );
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.boundOnMorph);
    document.removeEventListener("turbo:render", this.boundOnTurboRender);
    document.removeEventListener(
      "viral--alert:dismissed",
      this.boundOnViralAlertDismissed,
    );
  }

  onMorph() {
    this.#initializeSelectionState();
    this.#applyLimitAlertDismissedState();
  }

  onTurboRender() {
    this.#applyLimitAlertDismissedState();
  }

  /**
   * Toggle selection state for all rows on the current page.
   * When the page checkbox is checked, all row values are added to the selection;
   * when unchecked they are removed.
   * @param {Event} event - Change event from the page-level checkbox
   */
  togglePage(event) {
    const valuesToToggle = this.rowSelectionTargets.map((row) => row.value);
    this.#modifySelection(event.target.checked, valuesToToggle, {
      announceSelectPageStatus: false,
    });
  }

  /**
   * Toggle a single row selection. Supports shift-click range selection.
   * - If shiftKey is pressed and there is a last active checkbox id recorded,
   *   calculate the range between the previous checkbox and the clicked one and
   *   toggle every checkbox in that range.
   * @param {Event} event - Change event from an individual row checkbox
   */
  toggle(event) {
    let valuesToToggle = [event.target.value];

    // Shift-click range selection — only when the previous active checkbox still exists
    if (event.shiftKey && typeof this.#lastActiveCheckbox !== "undefined") {
      const startIndex = this.rowSelectionTargets.findIndex(
        (row) => row.id === this.#lastActiveCheckbox,
      );
      const endIndex = this.rowSelectionTargets.findIndex(
        (row) => row.id === event.target.id,
      );

      // Only perform range selection when both indices are valid.
      // This prevents an out-of-range slice if the stored lastActiveCheckbox
      // no longer exists in the current rowSelectionTargets (e.g. after a partial update).
      if (startIndex > -1 && endIndex > -1) {
        // Determine lower/higher bounds for the range
        const low = Math.min(startIndex, endIndex);
        const high = Math.max(startIndex, endIndex);

        // Only build the list when the adjusted range is non-empty
        if (low <= high) {
          const indices = [];
          for (let i = low; i <= high; i++) indices.push(i);
          valuesToToggle = indices.map(
            (i) => this.rowSelectionTargets[i].value,
          );
        } else {
          valuesToToggle = [];
        }
      }
    }

    this.#modifySelection(event.target.checked, valuesToToggle);
    this.#lastActiveCheckbox = event.target.id;
  }

  /**
   * Remove a single id from the selection (used by action buttons or other code).
   * Receives a Stimulus action parameter object: { params: { id } }
   * @param {{params: {id: string}}} param0
   */
  remove({ params: { id } }) {
    this.#modifySelection(false, [id]);
  }

  clear() {
    this.update([]);
  }

  update(ids, announce = true, options = {}) {
    if (!Array.isArray(ids)) {
      console.warn("SelectionController: ids must be an array");
      return;
    }

    if (this.#exceedsLimit(ids.length)) {
      this.#handleSelectionLimitExceeded();
      this.#refreshUIFromStorage();
      return;
    }

    if (!this.#persistSelection(ids)) {
      this.#handleSelectionLimitExceeded();
      this.#refreshUIFromStorage();
      return;
    }

    this.#hideSelectionLimitAlertIfAllowed();
    this.#updateUI(ids, announce, options);
  }

  getOrCreateStoredItems() {
    const storedItems = this.#readStoredItems();
    if (storedItems) {
      return storedItems;
    }

    this.update([], false);
    return [];
  }

  getStoredItemsCount() {
    return this.getOrCreateStoredItems().length;
  }

  /**
   * Modify the stored selection by adding or removing provided values, then
   * persist and update the UI.
   * @param {boolean} add - true to add values, false to remove
   * @param {Array<string>} values - array of ids to add or remove
   * @private
   */
  #modifySelection(add, values, options = {}) {
    let newStorageValue = this.getOrCreateStoredItems();
    if (add) {
      // Use a Set to deduplicate values
      newStorageValue = [...new Set([...newStorageValue, ...values])];
      if (this.#exceedsLimit(newStorageValue.length)) {
        this.#handleSelectionLimitExceeded();
        this.#refreshUIFromStorage();
        return;
      }
    } else {
      newStorageValue = newStorageValue.filter(
        (value) => !values.includes(value),
      );
    }
    this.update(newStorageValue, true, options);
  }

  /**
   * Update all UI elements to reflect the current selection state.
   * This updates row checkboxes, action buttons, counts and the page-level
   * select-all checkbox state.
   * @param {Array<string>} ids - current selection ids
   * @param {boolean} announce - whether to announce via aria-live region
   * @private
   */
  #updateUI(ids, announce, options = {}) {
    try {
      const idSet = new Set(ids);
      this.rowSelectionTargets.forEach((row) => {
        row.checked = idSet.has(row.value);
      });
    } catch (error) {
      console.error(
        "selectionController: Failed to update row checkboxes",
        error,
      );
    }

    this.#updateCounts(ids.length, announce);

    try {
      this.#updateActionButtons(ids.length);
      this.#setSelectPageCheckboxValue(
        options.announceSelectPageStatus ?? announce,
      );
    } catch (error) {
      console.error(
        "selectionController: Failed to update selection controls",
        error,
      );
    }
  }

  #updateActionButtons(count) {
    if (!this.element.hasAttribute("data-selection-action-button-outlet"))
      return;

    this.actionButtonOutlets.forEach((outlet) => {
      outlet.setDisabled(count);
    });
  }

  #setSelectPageCheckboxValue(shouldAnnounce) {
    if (this.hasSelectPageTarget) {
      const totalOnPage = this.rowSelectionTargets.length;
      const selectedOnPage = this.rowSelectionTargets.filter(
        (row) => row.checked,
      ).length;

      const allChecked = totalOnPage > 0 && selectedOnPage === totalOnPage;
      const noneChecked = selectedOnPage === 0;
      const mixed = !allChecked && !noneChecked;

      this.selectPageTarget.checked = allChecked;
      // Do not expose an indeterminate checkbox state here because many
      // screen readers announce it as "half checked", which is misleading
      // when an arbitrary subset (e.g. 1 of 8) is selected.
      this.selectPageTarget.indeterminate = false;
      this.#updateSelectPageDescription(mixed);

      this.#updateSelectPageStatusText(
        {
          selectedOnPage,
          totalOnPage,
          state: mixed ? "some" : allChecked ? "all" : "none",
        },
        shouldAnnounce,
      );
    }
  }

  #updateSelectPageStatusText({ selectedOnPage, totalOnPage, state }) {
    if (!this.hasSelectPageStatusTarget) return;

    const template = state === "some" ? this.selectPageSomeValue : "";

    const text = template
      .replace("%{selected}", String(selectedOnPage))
      .replace("%{total}", String(totalOnPage));

    this.selectPageStatusTarget.textContent = text;
  }

  #updateSelectPageDescription(mixed) {
    if (!this.hasSelectPageTarget || !this.hasSelectPageStatusTarget) return;

    if (mixed) {
      this.selectPageTarget.setAttribute(
        "aria-describedby",
        this.selectPageStatusTarget.id,
      );
    } else {
      this.selectPageTarget.removeAttribute("aria-describedby");
    }
  }

  #updateCounts(selected, announce) {
    if (this.hasSelectedTarget) {
      this.selectedTarget.innerText = selected;
    }
    if (announce) {
      this.#announceSelectionStatus(selected);
    }
  }

  /**
   * Announce current selection status to an aria-live region.
   *
   * @param {number} selected - Current number of selected items.
   * @private
   */
  #announceSelectionStatus(selected) {
    const messageTemplate = this.countMessageValue;

    // Skip announcement if this selection context is not configured with a count template.
    if (!messageTemplate) return;

    const message = messageTemplate
      .replace("%{selected}", String(selected))
      .replace("%{total}", String(this.totalValue || 0));

    if (this.hasStatusTarget) {
      announce(message, { element: this.statusTarget });
    } else {
      announce(message);
    }
  }

  #initializeSelectionState() {
    const storedItems = this.#readStoredItems() || [];

    if (this.#exceedsLimit(storedItems.length)) {
      this.#handleSelectionLimitExceeded({ resetDismissed: false });
      this.#updateUI(storedItems, false);
      return;
    }

    this.update(storedItems, false);
  }

  #readStoredItems() {
    try {
      const storedItems = JSON.parse(
        sessionStorage.getItem(this.#getStorageKey()),
      );
      if (Array.isArray(storedItems)) {
        return storedItems;
      }
    } catch (error) {
      console.warn("Failed to parse stored selection items:", error);
    }

    return null;
  }

  #persistSelection(ids) {
    try {
      sessionStorage.setItem(this.#getStorageKey(), JSON.stringify(ids));
      return true;
    } catch (error) {
      if (this.#isQuotaExceededError(error)) {
        return false;
      }

      throw error;
    }
  }

  #isQuotaExceededError(error) {
    return (
      error?.name === "QuotaExceededError" ||
      error?.code === 22 ||
      error?.code === "QuotaExceededError"
    );
  }

  #refreshUIFromStorage() {
    const storedItems = this.#readStoredItems() || [];
    this.#updateUI(storedItems, false);
  }

  #exceedsLimit(count) {
    return this.maxSelectionValue > 0 && count > this.maxSelectionValue;
  }

  #handleSelectionLimitExceeded({ resetDismissed = true } = {}) {
    if (resetDismissed) {
      this.#clearLimitAlertDismissed();
    } else if (this.#isLimitAlertDismissed()) {
      return;
    }

    this.#showSelectionLimitAlert();

    if (resetDismissed) {
      this.#announceSelectionLimitExceeded();
    }
  }

  #showSelectionLimitAlert() {
    const limitAlert = this.#findLimitAlertElement();
    if (!limitAlert || this.#isLimitAlertDismissed()) return;

    if (!this.#proactiveLimitAlert(limitAlert) && this.limitMessageValue) {
      const limitAlertMessage = this.#findLimitAlertMessageElement(limitAlert);
      if (limitAlertMessage) {
        limitAlertMessage.textContent = this.#selectionLimitMessage();
      }
    }

    limitAlert.classList.remove("hidden");
  }

  #hideSelectionLimitAlertIfAllowed() {
    const limitAlert = this.#findLimitAlertElement();
    if (!limitAlert) return;
    if (this.#proactiveLimitAlert(limitAlert)) return;

    limitAlert.classList.add("hidden");
    this.#clearLimitAlertDismissed();
  }

  #applyLimitAlertDismissedState() {
    const limitAlert = this.#findLimitAlertElement();
    if (!limitAlert) return;
    if (!this.#isLimitAlertDismissed()) return;

    limitAlert.classList.add("hidden");
  }

  #handleViralAlertDismissed(event) {
    const limitAlert = this.#findLimitAlertElement();
    if (!limitAlert || !limitAlert.contains(event.target)) {
      return;
    }

    this.#markLimitAlertDismissed();
    limitAlert.classList.add("hidden");
  }

  #findLimitAlertElement() {
    if (this.hasLimitAlertTarget) {
      return this.limitAlertTarget;
    }

    const parent = this.element.parentElement;
    const alertInParent = parent?.querySelector("#selection-limit-alert");
    if (alertInParent) return alertInParent;

    let sibling = this.element.previousElementSibling;
    while (sibling) {
      if (sibling.id === "selection-limit-alert") return sibling;
      sibling = sibling.previousElementSibling;
    }

    const tableContainer = this.element.closest(".table-container");
    if (!tableContainer) return null;

    sibling = tableContainer.previousElementSibling;
    while (sibling) {
      if (sibling.id === "selection-limit-alert") return sibling;
      sibling = sibling.previousElementSibling;
    }

    return null;
  }

  #findLimitAlertMessageElement(limitAlert) {
    if (this.hasLimitAlertMessageTarget) {
      return this.limitAlertMessageTarget;
    }

    return (
      limitAlert?.querySelector(
        "[data-selection-target='limitAlertMessage']",
      ) ?? null
    );
  }

  #limitAlertDismissedStorageKey() {
    return `${this.#getStorageKey()}:selection-limit-alert-dismissed`;
  }

  #isLimitAlertDismissed() {
    return (
      sessionStorage.getItem(this.#limitAlertDismissedStorageKey()) === "true"
    );
  }

  #markLimitAlertDismissed() {
    sessionStorage.setItem(this.#limitAlertDismissedStorageKey(), "true");
  }

  #clearLimitAlertDismissed() {
    sessionStorage.removeItem(this.#limitAlertDismissedStorageKey());
  }

  #proactiveLimitAlert(limitAlert = this.#findLimitAlertElement()) {
    return limitAlert?.dataset.selectionLimitProactive === "true";
  }

  #announceSelectionLimitExceeded() {
    const message = this.#selectionLimitMessage();
    if (!message) return;

    if (this.hasStatusTarget) {
      announce(message, {
        element: this.statusTarget,
        politeness: "assertive",
      });
    } else {
      announce(message, { politeness: "assertive" });
    }
  }

  #selectionLimitMessage() {
    if (!this.limitMessageValue) return "";

    return this.limitMessageValue.replace(
      "%{max}",
      String(this.maxSelectionValue),
    );
  }

  #getStorageKey() {
    return (
      this.storageKeyValue ||
      `${location.protocol}//${location.host}${location.pathname}`
    );
  }
}
