import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["row"];

  initialize() {
    this.boundKeydown = this.keydown.bind(this);
  }

  connect() {
    this.element.addEventListener("keydown", this.boundKeydown);
    this.element.setAttribute("data-controller-connected", "true");
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
        if (!this.#isExpanded(event.target)) {
          this.toggleRow(event);
        }
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
      }
    } else if (event.key === "Home") {
      if (this.rowTargets.includes(event.target) || event.ctrlKey) {
        this.#moveToExtremeRow(-1);
      }
    } else if (event.key === "End") {
      if (this.rowTargets.includes(event.target) || event.ctrlKey) {
        this.#moveToExtremeRow(+1);
      }
    } else if (event.key === "PageUp") {
      this.#moveToExtremeRow(-1);
    } else if (event.key === "PageDown") {
      this.#moveToExtremeRow(+1);
    }
  }

  toggleRow(event) {
    const row = this.#getContainingRow(event.target);

    this.#changeExpanded(!this.#isExpanded(row), row);
  }

  #moveByRow(direction) {
    const currentRow = this.#getRowWithFocus();
    const rows = this.#getAllNavigableRows();
    const numRows = rows.length;
    let rowIndex = rows.indexOf(currentRow);
    let newRowIndex = this.#restrictIndex(rowIndex + direction, numRows);

    if (newRowIndex != rowIndex) {
      currentRow.tabIndex = -1;
      this.#focus(rows[newRowIndex]);
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
      this.#focus(newRow);
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

  #focus(elem) {
    elem.tabIndex = 0;
    elem.focus();
  }

  #getLevel(row) {
    return row && parseInt(row.getAttribute("aria-level"));
  }

  #isExpanded(row) {
    return row.getAttribute("aria-expanded") === "true";
  }

  #changeExpanded(doExpand, row) {
    let currentRowIndex = this.rowTargets.indexOf(row);
    const currentLevel = this.#getLevel(row);
    let didChange;
    let doExpandLevel = [];
    doExpandLevel[currentLevel + 1] = doExpand;

    while (++currentRowIndex < this.rowTargets.length) {
      let nextRow = this.rowTargets[currentRowIndex];
      let rowLevel = this.#getLevel(nextRow);
      if (rowLevel <= currentLevel) {
        break; // Next row is not a level down from current row
      }

      // Only expand the next level if this level is expanded
      // and previous level is expanded
      doExpandLevel[rowLevel + 1] =
        doExpandLevel[rowLevel] && this.#isExpanded(nextRow);
      var willHideRow = !doExpandLevel[rowLevel];
      var isRowHidden = nextRow.classList.contains("hidden");

      if (willHideRow !== isRowHidden) {
        if (willHideRow) {
          nextRow.classList.add("hidden");
        } else {
          nextRow.classList.remove("hidden");
        }
        didChange = true;
      }
    }
    if (didChange) {
      this.#setAriaExpanded(row, doExpand);
      return true;
    }
  }

  #setAriaExpanded(row, doExpand) {
    row.setAttribute("aria-expanded", doExpand);
  }
}
