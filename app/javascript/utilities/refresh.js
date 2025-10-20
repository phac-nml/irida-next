/**
 * Notify refresh controllers to ignore the next broadcast caused by a user action.
 * Prevents showing "refresh available" notice for changes the user just made.
 *
 * This is useful when a controller action triggers a broadcast that would normally
 * show a refresh notice, but we want to suppress it because it was user-initiated.
 *
 * @param {Controller} controller - A Stimulus controller instance that has refresh outlets
 * @example
 *   import { notifyRefreshControllers } from "utilities/refresh";
 *
 *   export default class extends Controller {
 *     static outlets = ["refresh"];
 *
 *     handleSubmit() {
 *       notifyRefreshControllers(this);
 *       // ... submit logic
 *     }
 *   }
 */
export function notifyRefreshControllers(controller) {
  if (!controller.hasRefreshOutlet) return;

  controller.refreshOutlets.forEach((outlet) => {
    if (outlet && typeof outlet.ignoreNextRefresh === "function") {
      outlet.ignoreNextRefresh();
    }
  });
}
