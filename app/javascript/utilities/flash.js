export function ensureFlash(controller) {
  if (!controller._operationId) return null;
  const flashId = `${controller.identifier}-flash-${controller._operationId}`;

  let flash = document.getElementById(flashId);
  if (!flash) {
    flash = createFlash(controller, flashId);
  }

  return flash;
}

function createFlash(controller, flashId) {
  const flash = controller.flashTemplateTarget.content.cloneNode(true);
  flash.firstElementChild.id = flashId;
  const flashes = document.getElementById("flashes");
  flashes.appendChild(flash);
  return flashes.getElementById(flashId);
}
