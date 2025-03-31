import { Controller } from "@hotwired/stimulus";

/**
 * 🎛️ Controller for managing selection state (e.g., checkboxes in a table).
 * This controller persists the selection state in sessionStorage and updates
 * UI elements based on the current selection.
 *
 * @property {string} storageKeyValue - The key used for sessionStorage. Defaults to the current page URL.
 * @property {number} totalValue - The total number of items available (optional, used for display).
 * @property {HTMLElement[]} rowSelectionTargets - Checkbox elements for individual item selection.
 * @property {HTMLElement} selectPageTarget - Checkbox element to select/deselect all items on the current page.
 * @property {HTMLElement} selectedTarget - Element to display the count of selected items.
 * @property {ActionLinkOutlet[]} actionLinkOutlets - Outlets to associated action-link controllers.
 */
export default class extends Controller {
  // 🎯 Static properties for Stimulus configuration
  static targets = ["rowSelection", "selectPage", "selected"];
  static outlets = ["action-link"];
  static values = {
    storageKey: {
      type: String,
      default: "", // Default value handled in idempotentConnect
    },
    total: Number,
  };

  // #️⃣ Private instance variables
  #storageKey = null; // 🗝️ Key for sessionStorage
  #numSelected = 0; // 🔢 Count of currently selected items

  // 🔌 Lifecycle Callbacks --------------------------------------------------

  /**
   * Called when the controller is connected to the DOM.
   * Initializes the controller and loads the initial selection state. 🔗
   */
  connect() {
    this.idempotentConnect();
  }

  /**
   * Ensures connect logic runs only once, even if Stimulus reconnects.
   * Sets the storage key and loads initial state from sessionStorage. 🔄
   */
  idempotentConnect() {
    // Avoid re-running connection logic if already connected
    if (this.element.dataset.controllerConnected === "true") {
      return;
    }

    // Determine the sessionStorage key (use provided value or default to page URL)
    this.#storageKey =
      this.storageKeyValue ||
      `${location.protocol}//${location.host}${location.pathname}`;

    this.element.setAttribute("data-controller-connected", "true");

    // Load initial selection state from storage
    const storedItems = this.getStoredItems();
    this.#numSelected = storedItems.length;
    this.#updateUI(storedItems); // Update UI based on stored items
  }

  // 🎬 Public Actions ------------------------------------------------------

  /**
   * Toggles the selection state for all items currently visible on the page.
   * Triggered by the "Select Page" checkbox. 📄🖱️
   * @param {Event} event - The input change event.
   */
  togglePage(event) {
    const isChecked = event.target.checked;
    const currentStoredItems = this.getStoredItems();
    let itemsChanged = false;

    // Iterate over each row checkbox target
    this.rowSelectionTargets.forEach((rowCheckbox) => {
      const itemId = rowCheckbox.value;
      const currentlySelected = currentStoredItems.includes(itemId);

      // If the row's state needs to change to match the "Select Page" checkbox
      if (rowCheckbox.checked !== isChecked) {
        rowCheckbox.checked = isChecked; // Update checkbox state visually
        itemsChanged = true;

        // Add or remove the item ID from the stored list
        if (isChecked && !currentlySelected) {
          currentStoredItems.push(itemId);
        } else if (!isChecked && currentlySelected) {
          const index = currentStoredItems.indexOf(itemId);
          if (index > -1) {
            currentStoredItems.splice(index, 1);
          }
        }
      }
    });

    // If any items were changed, save the updated list and refresh the UI
    if (itemsChanged) {
      this.save(currentStoredItems);
      this.#updateUI(currentStoredItems);
    }
  }

  /**
   * Toggles the selection state for a single item.
   * Triggered by individual row checkboxes. ☑️🖱️
   * @param {Event} event - The input change event.
   */
  toggle(event) {
    this.#updateItemSelection(event.target.checked, event.target.value);
  }

  /**
   * Removes a specific item from the selection.
   * Typically called from another controller or UI element. ➖
   * @param {object} params - Parameters object.
   * @param {string} params.id - The ID of the item to remove.
   */
  remove({ params: { id } }) {
    this.#updateItemSelection(false, id.toString()); // Ensure ID is a string
  }

  /**
   * Clears the entire selection state from sessionStorage and updates the UI. 🗑️
   */
  clear() {
    sessionStorage.removeItem(this.#storageKey);
    this.save([]); // Save an empty array
    this.#updateUI([]); // Update UI to reflect empty selection
  }

  /**
   * Updates the selection state with a new array of IDs. 🔄
   * Useful for setting the selection programmatically.
   * @param {string[]} ids - An array of item IDs to be selected.
   */
  update(ids) {
    const stringIds = ids.map(String); // Ensure all IDs are strings
    this.save(stringIds);
    this.#updateUI(stringIds);
  }

  // 💾 Storage Management ---------------------------------------------------

  /**
   * Saves the current selection state (array of IDs) to sessionStorage. 💾
   * @param {string[]} selectedIds - Array of selected item IDs.
   */
  save(selectedIds) {
    // Ensure uniqueness and convert to strings before saving
    const uniqueStringIds = [...new Set(selectedIds.map(String))];
    sessionStorage.setItem(this.#storageKey, JSON.stringify(uniqueStringIds));
    this.#numSelected = uniqueStringIds.length; // Update internal count
  }

  /**
   * Retrieves the list of selected item IDs from sessionStorage.  retrieval. 📦
   * @returns {string[]} An array of selected item IDs, or an empty array if none are stored.
   */
  getStoredItems() {
    const storedValue = sessionStorage.getItem(this.#storageKey);
    try {
      // Parse the stored JSON, default to empty array if null or invalid
      return storedValue ? JSON.parse(storedValue) : [];
    } catch (e) {
      console.error("Error parsing stored selection:", e);
      return []; // Return empty array on parsing error
    }
  }

  /**
   * Adds or removes a single item ID from the stored selection. ➕➖
   * Saves the updated list and refreshes the UI.
   * @private
   * @param {boolean} add - True to add the item, false to remove it.
   * @param {string} itemId - The ID of the item to add or remove.
   */
  #updateItemSelection(add, itemId) {
    const currentStoredItems = this.getStoredItems();
    const index = currentStoredItems.indexOf(itemId);
    let changed = false;

    if (add && index === -1) {
      // Add item if it's not already present
      currentStoredItems.push(itemId);
      changed = true;
    } else if (!add && index > -1) {
      // Remove item if it exists
      currentStoredItems.splice(index, 1);
      changed = true;
    }

    // If the list changed, save and update UI
    if (changed) {
      this.save(currentStoredItems);
      this.#updateUI(currentStoredItems);
    }
  }

  // 🖼️ UI Updates ---------------------------------------------------------

  /**
   * Updates all relevant UI elements based on the current selection state. 🎨
   * @private
   * @param {string[]} selectedIds - Array of currently selected item IDs.
   */
  #updateUI(selectedIds) {
    // 1. Update individual row checkboxes
    this.rowSelectionTargets.forEach((rowCheckbox) => {
      rowCheckbox.checked = selectedIds.includes(rowCheckbox.value);
    });

    // 2. Update action link states (enable/disable)
    this.#updateActionLinks(selectedIds.length);

    // 3. Update the selected count display
    this.#updateCounts(selectedIds.length);

    // 4. Update the state of the "Select Page" checkbox
    this.#setSelectPageCheckboxValue();
  }

  /**
   * Enables or disables associated action links based on selection count. 🔗🚦
   * @private
   * @param {number} count - The number of currently selected items.
   */
  #updateActionLinks(count) {
    this.actionLinkOutlets.forEach((outlet) => {
      // Assuming action-link controller has a `setDisabled` method
      // or similar logic based on the count.
      // Modify this if your action-link outlet has a different API.
      if (typeof outlet.setDisabled === "function") {
        outlet.setDisabled(count);
      } else {
        // Fallback or alternative logic if setDisabled doesn't exist
        outlet.element.disabled = count === 0;
        // Example: Add/remove a disabled class
        // outlet.element.classList.toggle("disabled", count === 0);
      }
    });
  }

  /**
   * Sets the checked state of the "Select Page" checkbox. 📄✅
   * It should be checked if all visible items on the page are selected.
   * @private
   */
  #setSelectPageCheckboxValue() {
    if (this.hasSelectPageTarget && this.rowSelectionTargets.length > 0) {
      // Check if any row checkbox target on the page is *not* checked
      const anyUnchecked = this.rowSelectionTargets.some(
        (row) => !row.checked,
      );
      // If none are unchecked (all are checked), check the "Select Page" box
      this.selectPageTarget.checked = !anyUnchecked;
    } else if (this.hasSelectPageTarget) {
      // If no row targets, uncheck the select page target
      this.selectPageTarget.checked = false;
    }
  }

  /**
   * Updates the text content of the element displaying the selected count. 🔢📊
   * @private
   * @param {number} selectedCount - The number of selected items.
   */
  #updateCounts(selectedCount) {
    if (this.hasSelectedTarget) {
      this.selectedTarget.innerText = selectedCount.toString();
    }
  }

  // 🙋 Public Getters -------------------------------------------------------

  /**
   * Returns the current number of selected items. 💯
   * @returns {number} The count of selected items.
   */
  getNumSelected() {
    // Return the internally tracked count for efficiency
    return this.#numSelected;
  }
}
