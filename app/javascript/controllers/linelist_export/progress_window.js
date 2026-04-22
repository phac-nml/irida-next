const PROGRESS_WINDOW_ID = "linelist-export-progress-window";
const DISMISS_SELECTOR = '[data-linelist-export-dismiss="true"]';

export function updateProgressWindow(
  controller,
  message,
  percentage,
  error = false,
) {
  if (controller.progressWindowDismissed) return;

  const percent = Math.min(Math.max(percentage, 0), 100);
  ensureExportCard(controller);

  if (controller._progressMsgEl) {
    controller._progressMsgEl.textContent = message;
    if (error) {
      controller._progressMsgEl.setAttribute("role", "alert");
      controller._progressMsgEl.removeAttribute("aria-live");
    } else {
      controller._progressMsgEl.setAttribute("aria-live", "polite");
      controller._progressMsgEl.removeAttribute("role");
    }
  }

  if (controller._progressBarEl) {
    controller._progressBarEl.style.width = `${percent}%`;
    controller._progressBarEl.setAttribute(
      "aria-valuenow",
      Math.round(percent),
    );
    controller._progressBarEl.setAttribute("aria-label", message);
    controller._progressBarEl.classList.toggle("bg-red-600", error);
    controller._progressBarEl.classList.toggle("bg-primary-600", !error);
  }

  if (controller._progressPctEl) {
    controller._progressPctEl.textContent = `${Math.round(percent)}%`;
  }
}

export function showProgressWindow(controller, message) {
  if (!controller._progressWindowOpenedAt) {
    controller._progressWindowOpenedAt = Date.now();
  }

  updateProgressWindow(controller, message, 0);
}

export function scheduleProgressWindowDismiss(controller) {
  if (controller.progressWindowDismissed) return;

  clearProgressWindowDismissTimeout(controller);

  const openedAt = controller._progressWindowOpenedAt || Date.now();
  const elapsedMs = Date.now() - openedAt;
  const remainingMs = Math.max(
    controller.minimumVisibleDurationMsValue - elapsedMs,
    0,
  );

  controller._dismissProgressWindowTimeout = setTimeout(() => {
    dismissProgressWindow(controller);
  }, remainingMs);
}

export function clearProgressWindowDismissTimeout(controller) {
  if (!controller._dismissProgressWindowTimeout) return;

  clearTimeout(controller._dismissProgressWindowTimeout);
  controller._dismissProgressWindowTimeout = null;
}

export function dismissProgressWindow(controller) {
  clearProgressWindowDismissTimeout(controller);

  if (controller._exportId) {
    const card = document.getElementById(
      `linelist-export-card-${controller._exportId}`,
    );
    if (card) card.remove();
  }

  const container = document.getElementById(PROGRESS_WINDOW_ID);
  if (container && container.children.length === 0) container.remove();

  controller.progressWindowDismissed = true;
  controller._exportId = null;
  controller._progressWindowOpenedAt = null;
  controller._progressMsgEl = null;
  controller._progressBarEl = null;
  controller._progressPctEl = null;
}

function ensureExportCard(controller) {
  if (!controller._exportId) return null;

  const cardId = `linelist-export-card-${controller._exportId}`;
  let card = document.getElementById(cardId);

  if (!card) {
    card = createExportCard(controller, cardId);
  } else if (!controller._progressMsgEl) {
    // Recover refs after Turbo reconnect
    controller._progressMsgEl = card.querySelector(
      "[data-linelist-export-progress-message]",
    );
    controller._progressBarEl = card.querySelector(
      "[data-linelist-export-progress-bar]",
    );
    controller._progressPctEl = card.querySelector(
      "[data-linelist-export-progress-percent]",
    );
  }

  return card;
}

function ensureProgressContainer() {
  let container = document.getElementById(PROGRESS_WINDOW_ID);
  if (!container) {
    container = document.createElement("div");
    container.id = PROGRESS_WINDOW_ID;
    container.className = "fixed bottom-5 right-5 z-50 w-80 space-y-2";
    container.setAttribute("data-turbo-permanent", "");
    document.body.appendChild(container);
  }

  return container;
}

function createExportCard(controller, cardId) {
  const container = ensureProgressContainer();
  const card = document.createElement("div");
  card.id = cardId;
  card.addEventListener("click", (event) => {
    if (typeof controller.handleProgressWindowClick === "function") {
      controller.handleProgressWindowClick(event);
      return;
    }

    if (!event?.target?.closest?.(DISMISS_SELECTOR)) return;
    dismissProgressWindow(controller);
  });

  if (controller.hasProgressTemplateTarget) {
    const clone = controller.progressTemplateTarget.content.cloneNode(true);
    controller._progressMsgEl = clone.querySelector(
      "[data-linelist-export-progress-message]",
    );
    controller._progressBarEl = clone.querySelector(
      "[data-linelist-export-progress-bar]",
    );
    controller._progressPctEl = clone.querySelector(
      "[data-linelist-export-progress-percent]",
    );
    card.appendChild(clone);
  }

  container.appendChild(card);
  return card;
}
