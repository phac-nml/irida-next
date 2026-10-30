export function updateProgressWindow(
  controller,
  message,
  percentage,
  error = false,
) {
  /* v8 ignore next */
  if (controller.progressWindowDismissed) return;

  const percent = Math.min(Math.max(percentage, 0), 100);
  ensureCard(controller);

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
  /* v8 ignore next */
  if (controller.progressWindowDismissed) return;

  clearProgressWindowDismissTimeout(controller);

  const openedAt = controller._progressWindowOpenedAt || Date.now();
  const elapsedMs = Date.now() - openedAt;
  /* v8 ignore next 4 */
  const remainingMs = Math.max(
    controller.minimumVisibleDurationMsValue - elapsedMs,
    0,
  );

  controller._dismissProgressWindowTimeout = setTimeout(() => {
    dismissProgressWindow(controller);
  }, remainingMs);
}

export function clearProgressWindowDismissTimeout(controller) {
  /* v8 ignore next */
  if (!controller._dismissProgressWindowTimeout) return;

  clearTimeout(controller._dismissProgressWindowTimeout);
  controller._dismissProgressWindowTimeout = null;
}

export function dismissProgressWindow(controller) {
  clearProgressWindowDismissTimeout(controller);

  if (controller._operationId) {
    const card = document.getElementById(
      `${controller.identifier}-card-${controller._operationId}`,
    );
    if (card) card.remove();
  }

  const container = document.getElementById(
    `${controller.identifier}-progress-window`,
  );
  if (container && container.children.length === 0) container.remove();

  controller.progressWindowDismissed = true;
  controller._progressWindowOpenedAt = null;
  controller._progressMsgEl = null;
  controller._progressBarEl = null;
  controller._progressPctEl = null;
  controller._progressDismissEl = null;
}

export function setProgressDismissLabel(controller, label) {
  /* v8 ignore next */
  if (!controller._progressDismissEl) return;

  controller._progressDismissEl.setAttribute("aria-label", label);
}

function ensureCard(controller) {
  /* v8 ignore next */
  if (!controller._operationId) return null;

  const cardId = `${controller.identifier}-card-${controller._operationId}`;
  let card = document.getElementById(cardId);

  if (!card) {
    card = createCard(controller, cardId);
  } else {
    /* v8 ignore next 12 */
    if (!controller._progressMsgEl) {
      // Recover refs after Turbo reconnect
      controller._progressMsgEl = card.querySelector(
        `[data-${controller.identifier}-progress-message]`,
      );
      controller._progressBarEl = card.querySelector(
        `[data-${controller.identifier}-progress-bar]`,
      );
      controller._progressPctEl = card.querySelector(
        `[data-${controller.identifier}-progress-percent]`,
      );
      controller._progressDismissEl = card.querySelector(
        `[data-${controller.identifier}-dismiss]`,
      );
    }
  }

  return card;
}

function ensureProgressContainer(controller) {
  let container = document.getElementById(
    `${controller.identifier}-progress-window`,
  );
  /* v8 ignore next 8 */
  if (!container) {
    container = document.createElement("div");
    container.id = `${controller.identifier}-progress-window`;
    container.className = "fixed bottom-5 right-5 z-50 w-80 space-y-2";
    container.setAttribute("data-turbo-permanent", "");
    document.body.appendChild(container);
  }

  return container;
}

function createCard(controller, cardId) {
  const container = ensureProgressContainer(controller);
  const card = document.createElement("div");
  card.id = cardId;
  card.addEventListener("click", (event) => {
    /* v8 ignore next */
    if (
      !event?.target?.closest?.(
        `[data-${controller.identifier}-dismiss="true"]`,
      )
    )
      return;

    // Controllers that need to confirm/cancel in-flight work (e.g. an active
    // upload) can define handleProgressDismiss instead of dismissing outright.
    if (typeof controller.handleProgressDismiss === "function") {
      controller.handleProgressDismiss();
      return;
    }

    dismissProgressWindow(controller);
  });

  if (controller.hasProgressTemplateTarget) {
    const clone = controller.progressTemplateTarget.content.cloneNode(true);
    controller._progressMsgEl = clone.querySelector(
      `[data-${controller.identifier}-progress-message]`,
    );
    controller._progressBarEl = clone.querySelector(
      `[data-${controller.identifier}-progress-bar]`,
    );
    controller._progressPctEl = clone.querySelector(
      `[data-${controller.identifier}-progress-percent]`,
    );
    controller._progressDismissEl = clone.querySelector(
      `[data-${controller.identifier}-dismiss]`,
    );
    card.appendChild(clone);
  }

  container.appendChild(card);
  return card;
}
