/**
 * Closes the nearest viral dialog for an element by preferring the Stimulus
 * controller close action and falling back to the native dialog element.
 *
 * @param {Element} element - Element inside or near the dialog host.
 * @param {import("@hotwired/stimulus").Application} application - Stimulus application instance.
 */
export function closeDialog(element, application) {
  const dialogHost = element.closest('[data-controller~="viral--dialog"]');
  if (!dialogHost) return;

  const dialogController = application.getControllerForElementAndIdentifier(
    dialogHost,
    "viral--dialog",
  );

  if (dialogController?.close) {
    dialogController.close();
    return;
  }

  const dialogElement = dialogHost.querySelector(
    "[data-viral--dialog-target='dialog']",
  );

  if (dialogElement?.close) {
    dialogElement.close();
  }
}

export function ensureDialog(controller) {
  if (!controller._operationId) return null;
  const dialogId = `${controller.identifier}-dialog-${controller._operationId}`;

  let dialog = document.getElementById(dialogId);
  if (!dialog) {
    dialog = createDialog(controller, dialogId);
  }

  return dialog;
}

function createDialog(controller, dialogId) {
  const dialog = controller.dialogTemplateTarget.content.cloneNode(true);
  dialog.firstElementChild.id = dialogId;
  document.body.appendChild(dialog);
  return dialog;
}
