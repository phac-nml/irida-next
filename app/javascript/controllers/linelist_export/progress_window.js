const CONTAINER_ID = "linelist-export-progress-window";

function clampPercentage(value) {
  return Math.min(Math.max(value, 0), 100);
}

export class LinelistProgressWindow {
  constructor({ getTemplate }) {
    this.getTemplate = getTemplate;
    this.exportId = null;
    this.openedAt = null;
    this.dismissTimeout = null;
    this.dismissed = false;

    this.progressMsgEl = null;
    this.progressBarEl = null;
    this.progressPctEl = null;
    this.progressLinkEl = null;
    this.progressLinkRowEl = null;
  }

  beginSession() {
    this.clearDismissTimeout();
    this.exportId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    this.openedAt = null;
    this.dismissed = false;
    this.progressMsgEl = null;
    this.progressBarEl = null;
    this.progressPctEl = null;
    this.progressLinkEl = null;
    this.progressLinkRowEl = null;
  }

  show(message) {
    if (!this.openedAt) {
      this.openedAt = Date.now();
    }

    this.clearLink();
    this.update(message, 0);
  }

  update(message, percentage, error = false) {
    if (this.dismissed) return;

    const percent = clampPercentage(percentage);
    this.ensureExportCard();

    if (this.progressMsgEl) {
      this.progressMsgEl.textContent = message;
      if (error) {
        this.progressMsgEl.setAttribute("role", "alert");
        this.progressMsgEl.removeAttribute("aria-live");
      } else {
        this.progressMsgEl.setAttribute("aria-live", "polite");
        this.progressMsgEl.removeAttribute("role");
      }
    }

    if (this.progressBarEl) {
      this.progressBarEl.style.width = `${percent}%`;
      this.progressBarEl.setAttribute("aria-valuenow", Math.round(percent));
      this.progressBarEl.setAttribute("aria-label", message);
      this.progressBarEl.classList.toggle("bg-red-600", error);
      this.progressBarEl.classList.toggle("bg-primary-600", !error);
    }

    if (this.progressPctEl) {
      this.progressPctEl.textContent = `${Math.round(percent)}%`;
    }
  }

  dismiss() {
    this.clearDismissTimeout();

    if (this.exportId) {
      const card = document.getElementById(
        `linelist-export-card-${this.exportId}`,
      );
      if (card) card.remove();
    }

    const container = document.getElementById(CONTAINER_ID);
    if (container && container.children.length === 0) {
      container.remove();
    }

    this.dismissed = true;
    this.exportId = null;
    this.openedAt = null;
    this.progressMsgEl = null;
    this.progressBarEl = null;
    this.progressPctEl = null;
    this.progressLinkEl = null;
    this.progressLinkRowEl = null;
  }

  scheduleDismiss(minimumVisibleDurationMs, restartWindowTimer = false) {
    if (this.dismissed) return;

    this.clearDismissTimeout();
    if (restartWindowTimer) {
      this.openedAt = Date.now();
    }

    const openedAt = this.openedAt || Date.now();
    const elapsedMs = Date.now() - openedAt;
    const remainingMs = Math.max(minimumVisibleDurationMs - elapsedMs, 0);

    this.dismissTimeout = setTimeout(() => {
      this.dismiss();
    }, remainingMs);
  }

  clearDismissTimeout() {
    if (!this.dismissTimeout) return;

    clearTimeout(this.dismissTimeout);
    this.dismissTimeout = null;
  }

  setLink(url, text) {
    if (!url) {
      this.clearLink();
      return;
    }

    this.ensureExportCard();
    if (!this.progressLinkEl || !this.progressLinkRowEl) return;

    this.progressLinkEl.href = url;
    this.progressLinkEl.textContent = text;
    this.progressLinkRowEl.classList.remove("hidden");
  }

  clearLink() {
    if (this.progressLinkEl) {
      this.progressLinkEl.removeAttribute("href");
      this.progressLinkEl.textContent = "";
    }

    if (this.progressLinkRowEl) {
      this.progressLinkRowEl.classList.add("hidden");
    }
  }

  handleWindowClick(event) {
    if (!event?.target?.closest?.('[data-linelist-export-dismiss="true"]')) {
      return;
    }

    this.dismiss();
  }

  ensureExportCard() {
    if (!this.exportId) return null;

    const cardId = `linelist-export-card-${this.exportId}`;
    let card = document.getElementById(cardId);

    if (!card) {
      card = this.createExportCard(cardId);
    } else if (!this.progressMsgEl) {
      this.recoverCardRefs(card);
    }

    return card;
  }

  ensureProgressContainer() {
    let container = document.getElementById(CONTAINER_ID);

    if (!container) {
      container = document.createElement("div");
      container.id = CONTAINER_ID;
      container.className = "fixed bottom-5 right-5 z-50 w-80 space-y-2";
      container.setAttribute("data-turbo-permanent", "");
      document.body.appendChild(container);
    }

    return container;
  }

  createExportCard(cardId) {
    const container = this.ensureProgressContainer();
    const card = document.createElement("div");
    card.id = cardId;
    card.addEventListener("click", (event) => this.handleWindowClick(event));

    const template = this.getTemplate?.();
    if (template) {
      const clone = template.content.cloneNode(true);
      this.progressMsgEl = clone.querySelector(
        "[data-linelist-export-progress-message]",
      );
      this.progressBarEl = clone.querySelector(
        "[data-linelist-export-progress-bar]",
      );
      this.progressPctEl = clone.querySelector(
        "[data-linelist-export-progress-percent]",
      );
      this.progressLinkEl = clone.querySelector(
        "[data-linelist-export-target='progressLink']",
      );
      this.progressLinkRowEl = clone.querySelector(
        "[data-linelist-export-target='progressLinkRow']",
      );
      card.appendChild(clone);
    }

    container.appendChild(card);
    return card;
  }

  recoverCardRefs(card) {
    this.progressMsgEl = card.querySelector(
      "[data-linelist-export-progress-message]",
    );
    this.progressBarEl = card.querySelector(
      "[data-linelist-export-progress-bar]",
    );
    this.progressPctEl = card.querySelector(
      "[data-linelist-export-progress-percent]",
    );
    this.progressLinkEl = card.querySelector(
      "[data-linelist-export-target='progressLink']",
    );
    this.progressLinkRowEl = card.querySelector(
      "[data-linelist-export-target='progressLinkRow']",
    );
  }
}
