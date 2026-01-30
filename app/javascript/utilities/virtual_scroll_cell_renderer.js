/**
 * VirtualScrollCellRenderer
 *
 * Handles DOM manipulation for rendering virtualized table cells.
 * Manages cell cloning from templates, spacer creation, and efficient
 * cell reuse to minimize DOM operations during scrolling.
 *
 * Key optimizations:
 * - Reuses existing cells when possible (avoids recreating DOM nodes)
 * - Preserves cells currently being edited
 * - Uses document fragments for batch DOM updates
 * - Creates spacer cells for off-screen columns
 *
 * @example
 *   import { VirtualScrollCellRenderer } from "utilities/virtual_scroll_cell_renderer";
 *
 *   const renderer = new VirtualScrollCellRenderer({
 *     metadataFields: ['field1', 'field2', 'field3'],
 *     numBaseColumns: 3,
 *     metadataColumnWidths: [300, 250, 300],
 *     columnWidthFallback: 300
 *   });
 *
 *   // Render cells for a row
 *   renderer.renderRowCells(row, {
 *     firstVisible: 0,
 *     lastVisible: 10,
 *     templateContainer: templatesElement
 *   });
 */
export class VirtualScrollCellRenderer {
  /**
   * Create a cell renderer
   * @param {Object} options - Configuration options
   * @param {string[]} options.metadataFields - Array of metadata field names
   * @param {number} options.numBaseColumns - Number of non-virtualized base columns
   * @param {number[]} options.metadataColumnWidths - Array of metadata column widths
   * @param {number} [options.columnWidthFallback=300] - Fallback width for unmeasured columns
   */
  constructor(options) {
    this.metadataFields = options.metadataFields;
    this.numBaseColumns = options.numBaseColumns;
    this.metadataColumnWidths = options.metadataColumnWidths;
    this.columnWidthFallback = options.columnWidthFallback || 300;
  }

  /**
   * Render cells for a table row based on visible range
   * @param {HTMLElement} row - The table row element
   * @param {Object} options - Rendering options
   * @param {number} options.firstVisible - First visible column index
   * @param {number} options.lastVisible - Last visible column index
   * @param {HTMLElement} options.templateContainer - Container with cell templates
   */
  renderRowCells(row, options) {
    const { firstVisible, lastVisible, templateContainer } = options;
    const sampleId = row.dataset.sampleId;

    // Find cell currently being edited (must be preserved)
    const editingCellInfo = this.getEditingCellInfo(row);

    // Get template source for this row
    const templates = templateContainer?.querySelector(
      `[data-sample-id="${sampleId}"]`,
    );

    // Categorize existing cells
    const { baseColumns, existingCells } = this.categorizeRowCells(
      row,
      editingCellInfo?.cell,
    );

    // Build set of fields that should be visible
    const visibleFields = new Set();
    for (let i = firstVisible; i < lastVisible; i++) {
      const field = this.metadataFields[i];
      if (field) visibleFields.add(field);
    }

    // Build fragment with correctly ordered cells
    const fragment = this.buildCellFragment({
      baseColumns,
      existingCells,
      visibleFields,
      firstVisible,
      lastVisible,
      editingCellInfo,
      templates,
    });

    // Replace row children with fragment (batch update)
    while (row.firstChild) row.removeChild(row.firstChild);
    row.appendChild(fragment);
  }

  /**
   * Build document fragment with cells in correct order
   * @param {Object} options - Fragment building options
   * @returns {DocumentFragment} Fragment with ordered cells
   * @private
   */
  buildCellFragment(options) {
    const {
      baseColumns,
      existingCells,
      visibleFields,
      firstVisible,
      lastVisible,
      editingCellInfo,
      templates,
    } = options;

    const fragment = document.createDocumentFragment();

    // 1. Append base columns
    baseColumns.forEach((el) => fragment.appendChild(el));

    // 2. Start spacer (for hidden columns before visible range)
    if (firstVisible > 0) {
      fragment.appendChild(this.createSpacer(firstVisible));
    }

    // 3. Add metadata cells in order
    for (let i = firstVisible; i < lastVisible; i++) {
      const field = this.metadataFields[i];
      if (!field) continue;

      const cell = this.getCellForColumn(i, field, {
        existingCells,
        templates,
        editingCellInfo,
      });

      if (cell) {
        this.applyMetadataCellStyles(cell, i);
        fragment.appendChild(cell);
      }
    }

    // 4. End spacer (for hidden columns after visible range)
    if (lastVisible < this.metadataFields.length) {
      fragment.appendChild(
        this.createSpacer(this.metadataFields.length - lastVisible),
      );
    }

    return fragment;
  }

  /**
   * Get cell for a specific column, reusing existing or cloning from template
   * @param {number} columnIndex - Column index
   * @param {string} field - Field name
   * @param {Object} options - Cell retrieval options
   * @returns {HTMLElement|null} Cell element
   * @private
   */
  getCellForColumn(columnIndex, field, options) {
    const { existingCells, templates, editingCellInfo } = options;

    // Use editing cell if this is the column being edited
    if (
      editingCellInfo &&
      editingCellInfo.columnIndex === columnIndex &&
      editingCellInfo.cell
    ) {
      const cell = editingCellInfo.cell;
      cell.dataset.virtualizedCell = "true";
      return cell;
    }

    // Reuse existing cell if available
    const existingCell = existingCells.get(field);
    if (existingCell) {
      existingCell.dataset.virtualizedCell = "true";
      existingCells.delete(field); // Mark as used
      return existingCell;
    }

    // Clone from template (or return placeholder if template missing)
    return this.cloneCellFromTemplate(field, templates, columnIndex);
  }

  /**
   * Clone a cell from template, or return placeholder if template not available
   * @param {string} field - Field name
   * @param {HTMLElement} templates - Templates container
   * @param {number} columnIndex - Column index in metadata fields
   * @returns {HTMLElement|null} Cloned cell element or placeholder
   * @private
   */
  cloneCellFromTemplate(field, templates, columnIndex) {
    // Return placeholder if no templates container
    if (!templates) return this.createPlaceholderCell(field, columnIndex);

    const selector = `template[data-field="${CSS.escape(field)}"]`;
    const template = templates.querySelector(selector);

    // Return placeholder if template not found (deferred loading)
    if (!template) {
      return this.createPlaceholderCell(field, columnIndex);
    }

    const clonedContent = template.content.cloneNode(true);
    const cellElement = clonedContent.firstElementChild;

    // Return placeholder if template content is empty
    if (!cellElement) {
      return this.createPlaceholderCell(field, columnIndex);
    }

    cellElement.dataset.virtualizedCell = "true";
    cellElement.dataset.fieldId = field;

    return cellElement;
  }

  /**
   * Categorize row cells into base columns and existing virtualized cells
   * @param {HTMLElement} row - The table row
   * @param {HTMLElement|null} editingCell - Cell currently being edited (to preserve)
   * @returns {{baseColumns: HTMLElement[], existingCells: Map<string, HTMLElement>}}
   * @private
   */
  categorizeRowCells(row, editingCell) {
    const allChildren = Array.from(row.children).filter(
      (c) => c.tagName.toLowerCase() !== "template",
    );

    const baseColumns = [];
    const virtualizedCells = [];

    for (const child of allChildren) {
      if (child.dataset.virtualizedCell) {
        virtualizedCells.push(child);
      } else if (baseColumns.length < this.numBaseColumns) {
        baseColumns.push(child);
      } else {
        virtualizedCells.push(child);
      }
    }

    // Index existing virtualized cells by fieldId for reuse
    const existingCells = new Map();
    for (const cell of virtualizedCells) {
      // Skip the cell being edited
      if (editingCell && cell === editingCell) continue;

      const fieldId = cell.dataset.fieldId;
      if (fieldId && fieldId !== "undefined") {
        existingCells.set(fieldId, cell);
      }
    }

    return { baseColumns, existingCells };
  }

  /**
   * Get info about the cell currently being edited in a row
   * @param {HTMLElement} row - The table row
   * @returns {{cell: HTMLElement, columnIndex: number}|null}
   * @private
   */
  getEditingCellInfo(row) {
    const editingCell = this.findEditingCellInElement(row);
    if (!editingCell) return null;

    const fieldId = editingCell.dataset.fieldId;
    if (!fieldId) return null;

    const columnIndex = this.metadataFields.indexOf(fieldId);
    if (columnIndex === -1) return null;

    return { cell: editingCell, columnIndex };
  }

  /**
   * Find cell currently being edited in an element
   * @param {HTMLElement} root - Root element to search
   * @returns {HTMLElement|null} Editing cell or null
   * @private
   */
  findEditingCellInElement(root) {
    if (!root) return null;

    // Check for explicitly marked editing cell
    const markedEditingCell = root.querySelector?.('[data-editing="true"]');
    if (markedEditingCell) return markedEditingCell;

    // Check if active element is in this root
    const activeElement = document.activeElement;
    if (!activeElement || !(activeElement instanceof Element)) return null;
    if (!root.contains(activeElement)) return null;

    return activeElement.closest("[data-field-id]");
  }

  /**
   * Create a spacer cell with colspan
   * @param {number} colspan - Number of columns to span
   * @returns {HTMLElement} Spacer element
   * @private
   */
  createSpacer(colspan) {
    const spacer = document.createElement("td");
    spacer.colSpan = colspan;
    spacer.dataset.virtualizedCell = "true";
    spacer.setAttribute("role", "presentation");
    spacer.setAttribute("aria-hidden", "true");
    spacer.tabIndex = -1;

    Object.assign(spacer.style, {
      padding: "0",
      border: "none",
      width: "0",
    });

    return spacer;
  }

  /**
   * Create a placeholder cell for templates not yet loaded
   * @param {string} field - Field name
   * @param {number} columnIndex - Column index in metadata fields
   * @returns {HTMLElement} Placeholder cell element
   */
  createPlaceholderCell(field, columnIndex) {
    const cell = document.createElement("td");
    cell.dataset.virtualizedCell = "true";
    cell.dataset.fieldId = field;
    cell.dataset.placeholder = "true";
    cell.setAttribute("role", "gridcell");
    cell.setAttribute("aria-colindex", this.numBaseColumns + columnIndex + 1);
    cell.setAttribute("aria-busy", "true");
    cell.tabIndex = -1;

    const width =
      this.metadataColumnWidths[columnIndex] ?? this.columnWidthFallback;
    Object.assign(cell.style, {
      display: "table-cell",
      boxSizing: "border-box",
      width: `${width}px`,
      minWidth: `${width}px`,
      maxWidth: `${width}px`,
      overflow: "hidden",
    });

    // Add loading indicator with proper styling
    cell.classList.add("px-3", "py-3", "text-slate-400", "dark:text-slate-600");
    cell.textContent = "…";

    return cell;
  }

  /**
   * Apply styles to metadata cells including overflow handling
   * @param {HTMLElement} cell - The cell element
   * @param {number} columnIndex - Column index in metadata fields
   * @private
   */
  applyMetadataCellStyles(cell, columnIndex) {
    if (!cell) return;

    const width =
      this.metadataColumnWidths[columnIndex] ?? this.columnWidthFallback;

    cell.setAttribute("role", "gridcell");
    cell.tabIndex = -1;

    Object.assign(cell.style, {
      display: "table-cell",
      boxSizing: "border-box",
      width: `${width}px`,
      minWidth: `${width}px`,
      maxWidth: `${width}px`,
      overflow: "hidden",
      textOverflow: "ellipsis",
      whiteSpace: "nowrap",
    });

    // Add ARIA colindex for accessibility (1-based, includes base columns)
    const ariaColindex = this.numBaseColumns + columnIndex + 1;
    cell.setAttribute("aria-colindex", ariaColindex);
  }

  /**
   * Update metadata column widths
   * @param {number[]} newWidths - Updated array of column widths
   */
  updateColumnWidths(newWidths) {
    this.metadataColumnWidths = newWidths;
  }
}
