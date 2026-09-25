---
id: samples_cursor_grid
title: Project samples cursor grid
---

The `data_grid_samples_table` feature flag enables cursor browsing on Project samples when the installed Pathogen library exposes `DataGridComponent#virtual_cursor_pagination?`. Group samples keep their existing table behaviour. Older Pathogen releases keep the existing V2 table; they do not receive cursor options.

The pilot supports browsing, the existing single-column sort (including metadata), and filters. Selection, bulk actions and inline editing remain in the standard V1 table, accessible with `table_view=standard` and the current query. The view-switch entry point is managed separately from the cursor toolbar.

## Query and response contract

The initial page and `/samples/rows.json` use the same authorized Project query, fixed pixel column widths and cell renderers. Row requests include the complete `q` parameters and `limit`, plus an opaque signed cursor. They never update the stored search preferences. Batch size follows the host Pagy options: 20 by default and at most 100.

The initial results render performs one `COUNT` over the same authorized, filtered Project relation. This supplies the full total immediately in the footer and the grid row count. A scoped filter, sort or refresh starts a new result set and repeats that single count. The cursor service and `/samples/rows.json` remain free of count and offset queries, including continuation pages. The total describes the result set when it was counted; exhaustion reconciles the displayed total with the rows actually discovered.

Responses contain `rows: [{index, html}]` and `next_cursor`. A null next cursor marks exhaustion. The service signs the Project, query, sort, batch size and row offset; invalid cursors return HTTP 422 with `error: "invalid_cursor"`. Changing filters or sort starts a fresh chain by replacing only the `project-samples-results` Turbo frame. The cursor is not a database snapshot: concurrent record changes can change which rows a later request sees.

Sort headers are native Pathogen buttons that fill their header cells, with left-aligned labels and an inset focus outline. A persistent polite status region announces the accepted sort after a matching frame response. The host restores the same header control and horizontal position after the replacement unless focus has moved outside the frame. Only the 240px PUID column stays pinned on wide grids. Below 48rem of grid width, all columns scroll together while headers remain vertically sticky. A scoped stylesheet fallback provides the same narrow behaviour for the published regular V2 grid until the paired Pathogen release is installed. Sample links navigate outside the result frame. Broadcast update notices refresh the result frame through its current query URL. A shared request coordinator cancels superseded sort, filter, metadata and refresh requests. The server echoes a request identity so even a response already waiting to render cannot overwrite newer results. Unsupported Project sorts return HTTP 422 and a visible validation message.

The cursor table uses the remaining page height, keeping the existing bottom padding and a scrollable body when there are enough rows. Short result sets stay compact. The layout follows the real page header and controls, so filter replacement, wrapped controls and viewport resizing do not rely on a fixed table-height cap. Very short viewports retain outer page scrolling so the grid footer stays reachable.

## Local validation and rollout

This host change needs the matching Pathogen cursor release before enabling the new behaviour in production. Keep the published gem pin until that release is available, then update it in a separate dependency change and verify the browser flows together. The capability check prevents an already enabled flag from passing unsupported options to an older library.

This host still uses importmap. Its explicit asset-path and importmap bridge publishes the gem source modules and reuses the existing Stimulus instance. Remove that bridge when the independent host JavaScript bundling migration lands. A stale generated `app/assets/builds/application.js` can shadow the source entry point; keep local generated assets aligned with the current host branch.

For local paired development, set `USE_LOCAL_PATHOGEN=1` with the sibling checkout as described in [Useful commands](./useful_commands.md). Run focused tests with `PARALLEL_WORKERS=4`, including:

- `test/services/samples/cursor_page_test.rb`
- `test/controllers/projects/samples_cursor_controller_test.rb`
- `test/components/samples/table_v2_cursor_component_test.rb`
- `test/javascript/controllers/samples_cursor_controller.test.js`
- `test/javascript/controllers/refresh_controller.test.js`
- `test/system/projects/samples_cursor_test.rb`

Do not commit the generated local-path `Gemfile.lock`. Before enabling broadly, verify keyboard and screen-reader navigation, delayed and failed requests, horizontal sort focus, filter replacement during a fetch, and the standard-table route with its query preserved in a real browser.
