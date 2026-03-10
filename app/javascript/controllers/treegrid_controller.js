import { Controller } from "@hotwired/stimulus";
import { tabbable } from "tabbable";

export default class extends Controller {
  static targets = ["row"];
  static values = {
    expandText: String,
    collapseText: String,
  };

  initialize() {
    this.boundKeydown = this.keydown.bind(this);
  }

  connect() {
    this.element.addEventListener("keydown", this.boundKeydown);
    this.element.setAttribute("data-controller-connected", "true");

    // Make sure focusable elements are not in the tab order
    // They will be added back in for the active row
    this.#setTabIndexOfFocusableElements(this.element, -1);

    this.rowTargets[0].tabIndex = 0;
    this.#setTabIndexForElementsInRow(this.rowTargets[0], 0);
  }

  rowTargetConnected(row) {
    if (
      row !== document.activeElement &&
      !row.contains(document.activeElement)
    ) {
      this.#setTabIndexForElementsInRow(row, -1);
    }
  }

  keydown(event) {
    if (event.key === "ArrowDown" && !event.ctrlKey && !event.shiftKey) {
      this.#moveByRow(+1);
    } else if (event.key === "ArrowUp" && !event.ctrlKey && !event.shiftKey) {
      this.#moveByRow(-1);
    } else if (event.key === "ArrowRight") {
      if (
        this.rowTargets.includes(event.target) &&
        !event.ctrlKey &&
        !event.shiftKey
      ) {
        if (
          this.#isExpandable(event.target) &&
          !this.#isExpanded(event.target)
        ) {
          this.toggleRow(event);
        } else {
          this.#navigateRow(+1);
        }
      } else {
        this.#navigateRow(+1);
      }
    } else if (event.key === "ArrowLeft") {
      if (
        this.rowTargets.includes(event.target) &&
        !event.ctrlKey &&
        !event.shiftKey
      ) {
        if (this.#isExpanded(event.target)) {
          this.toggleRow(event);
        }
      } else {
        this.#navigateRow(-1);
      }
    } else if (event.key === "Home") {
      if (this.rowTargets.includes(event.target) || event.ctrlKey) {
        this.#moveToExtremeRow(-1);
      } else {
        this.#navigateToExtremeCell(-1);
      }
    } else if (event.key === "End") {
      if (this.rowTargets.includes(event.target) || event.ctrlKey) {
        this.#moveToExtremeRow(+1);
      } else {
        this.#navigateToExtremeCell(+1);
      }
    } else if (event.key === "PageUp") {
      this.#moveToExtremeRow(-1);
    } else if (event.key === "PageDown") {
      this.#moveToExtremeRow(+1);
    } else if (event.key === "Tab") {
      this.#handleTab(event);
    } else {
      return;
    }

    event.preventDefault();
  }

  #handleTab(event) {
    const direction = event.shiftKey ? -1 : +1;
    const currentRow = this.#getRowWithFocus();

    const focusableElements = tabbable(document);
    const currentIndex = focusableElements.indexOf(event.target);
    let nextElement = null;
    for (
      let i = currentIndex + direction;
      i >= 0 && i < focusableElements.length;
      i += direction
    ) {
      if (
        currentRow.contains(focusableElements[i]) ||
        !this.element.contains(focusableElements[i])
      ) {
        nextElement = focusableElements[i];
        break;
      }
    }
    if (nextElement) {
      nextElement.focus();
    }
    event.preventDefault();
  }

  toggleRow(event) {
    const row = this.#getContainingRow(event.target);

    this.#changeExpanded(!this.#isExpanded(row), row);
  }

  #navigateRow(direction) {
    const currentRow = this.#getRowWithFocus();

    const rowFocusableTargets = tabbable(currentRow);

    const currentIndex = rowFocusableTargets.indexOf(document.activeElement);
    const newIndex = currentIndex + direction;

    if (newIndex < 0) {
      currentRow.focus();
    } else if (newIndex < rowFocusableTargets.length) {
      rowFocusableTargets[newIndex].focus();
    }
  }

  #navigateToExtremeCell(direction) {
    const currentRow = this.#getRowWithFocus();

    const rowFocusableTargets = tabbable(currentRow);

    const newIndex = direction > 0 ? rowFocusableTargets.length - 1 : 0;
    const newCell = rowFocusableTargets[newIndex];

    if (document.activeElement !== newCell) {
      newCell.focus();
    }
  }

  #moveByRow(direction) {
    const currentRow = this.#getRowWithFocus();
    const rows = this.#getAllNavigableRows();
    const numRows = rows.length;
    const rowIndex = rows.indexOf(currentRow);
    const newRowIndex = this.#restrictIndex(rowIndex + direction, numRows);

    if (newRowIndex !== rowIndex) {
      const cellIndex = tabbable(currentRow).indexOf(document.activeElement);
      currentRow.tabIndex = -1;
      this.#setTabIndexForElementsInRow(currentRow, -1);
      this.#focus(rows[newRowIndex], cellIndex);
    }
  }

  #restrictIndex(index, numItems) {
    if (index < 0) {
      return 0;
    }
    return index >= numItems ? index - 1 : index;
  }

  #moveToExtremeRow(direction) {
    const currentRow = this.#getRowWithFocus();
    const rows = this.#getAllNavigableRows();
    const newRow = rows[direction > 0 ? rows.length - 1 : 0];

    if (currentRow !== newRow) {
      currentRow.tabIndex = -1;
      this.#focus(newRow, -1);
    }
  }

  #getRowWithFocus() {
    return this.#getContainingRow(document.activeElement);
  }

  #getContainingRow(start) {
    let possibleRow = start;
    if (!this.rowTargets.includes(possibleRow)) {
      possibleRow = possibleRow.closest(".treegrid-row");
    }
    return possibleRow;
  }

  #getAllNavigableRows() {
    return this.rowTargets.filter((row) => !row.classList.contains("hidden"));
  }

  #focus(elem, cellIndex) {
    elem.tabIndex = 0;
    this.#setTabIndexForElementsInRow(elem, 0);
    if (cellIndex < 0) {
      elem.focus();
    } else {
      const focusableRowTargets = tabbable(elem);
      if (cellIndex < focusableRowTargets.length) {
        focusableRowTargets[cellIndex].focus();
      } else {
        focusableRowTargets[focusableRowTargets.length - 1].focus();
      }
    }
  }

  #getLevel(row) {
    return row && parseInt(row.getAttribute("aria-level"));
  }

  #isExpandable(row) {
    return row.hasAttribute("aria-expanded");
  }

  #isExpanded(row) {
    return row.getAttribute("aria-expanded") === "true";
  }

  #changeExpanded(doExpand, row) {
    const toggleButton = row.querySelector(".treegrid-row-toggle");
    if (toggleButton.hasAttribute("data-toggle-url")) {
      const toggleUrl = new URL(toggleButton.getAttribute("data-toggle-url"));
      toggleUrl.searchParams.append("tabindex", row.tabIndex);
      fetch(toggleUrl.href, {
        credentials: "same-origin",
        headers: { Accept: "text/vnd.turbo-stream.html" },
      })
        .then((r) => r.text())
        .then((html) => Turbo.renderStreamMessage(html));
    } else {
      let currentRowIndex = this.rowTargets.indexOf(row);
      const currentLevel = this.#getLevel(row);
      let didChange;
      const doExpandLevel = [];
      doExpandLevel[currentLevel + 1] = doExpand;

      while (++currentRowIndex < this.rowTargets.length) {
        const nextRow = this.rowTargets[currentRowIndex];
        const rowLevel = this.#getLevel(nextRow);
        if (rowLevel <= currentLevel) {
          break; // Next row is not a level down from current row
        }

        // Only expand the next level if this level is expanded
        // and previous level is expanded
        doExpandLevel[rowLevel + 1] =
          doExpandLevel[rowLevel] && this.#isExpanded(nextRow);
        const willHideRow = !doExpandLevel[rowLevel];
        const isRowHidden = nextRow.classList.contains("hidden");

        if (willHideRow !== isRowHidden) {
          if (willHideRow) {
            nextRow.classList.add("hidden");
            // if row was currently tabbable then move tabindex to first row
            if (nextRow.tabIndex === 0) {
              nextRow.tabIndex = -1;
              this.#setTabIndexForElementsInRow(nextRow, -1);
              // set first row as tabbable
              this.rowTargets[0].tabIndex = 0;
              this.#setTabIndexForElementsInRow(this.rowTargets[0], 0);
            }
          } else {
            nextRow.classList.remove("hidden");
          }
          didChange = true;
        }
      }
      if (didChange) {
        this.#setAriaExpanded(row, doExpand);
        this.#setToggleButtonText(toggleButton, doExpand);

        return true;
      }
    }
  }

  #setAriaExpanded(row, doExpand) {
    row.setAttribute("aria-expanded", doExpand);
  }

  #setToggleButtonText(toggleButton, doExpand) {
    if (doExpand) {
      toggleButton.setAttribute("aria-label", this.collapseTextValue);
    } else {
      toggleButton.setAttribute("aria-label", this.expandTextValue);
    }
  }

  #setTabIndexOfFocusableElements(element, tabIndex) {
    tabbable(element).forEach((el) => {
      el.tabIndex = tabIndex;
    });
  }

  #setTabIndexForElementsInRow(row, tabIndex) {
    if (tabIndex !== -1) {
      row.querySelectorAll("[tabindex]").forEach((el) => {
        // ignore toggle buttons
        if (el.getAttribute("data-action") !== "click->treegrid#toggleRow") {
          el.tabIndex = tabIndex;
        }
      });
    } else {
      tabbable(row).forEach((el) => {
        // ignore toggle buttons
        if (el.getAttribute("data-action") !== "click->treegrid#toggleRow") {
          el.tabIndex = tabIndex;
        }
      });
    }
  }
}
