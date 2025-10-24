// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "flowbite";
import { createFocusTrap } from "focus-trap";

import * as ActiveStorage from "@rails/activestorage";

ActiveStorage.start();

const processLocalTimes = (root = document) => {
  if (!window.LocalTime) return;

  const timeElements = root.querySelectorAll("time[data-local]");
  if (timeElements.length === 0) return;

  LocalTime.config.locale = document.documentElement.lang;
  LocalTime.process(...timeElements);
};

function isElementInViewport(el) {
  var rect = el.getBoundingClientRect();

  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <=
      (window.innerHeight ||
        document.documentElement.clientHeight) /* or $(window).height() */ &&
    rect.right <=
      (window.innerWidth ||
        document.documentElement.clientWidth) /* or $(window).width() */
  );
}

document.addEventListener("turbo:render", () => {
  processLocalTimes();
  // ensure focused element is scrolled into view if out of view
  if (!isElementInViewport(document.activeElement)) {
    document.activeElement.scrollIntoView();
  }
});

document.addEventListener("turbo:frame-load", (event) => {
  const frame = event.target;
  if (!(frame instanceof HTMLElement)) return;

  processLocalTimes(frame);
});

document.addEventListener("turbo:before-stream-render", (event) => {
  const originalRender = event.detail.render;

  event.detail.render = (streamElement) => {
    originalRender(streamElement);

    const targetIdentifier =
      streamElement.target || streamElement.getAttribute?.("target");
    const target =
      streamElement.targetElement ||
      (targetIdentifier && document.getElementById(targetIdentifier)) ||
      (targetIdentifier && document.querySelector(`[id="${targetIdentifier}"]`));

    processLocalTimes(target || document);
  };
});

Turbo.config.forms.confirm = (message, element) => {
  const dialog = document.getElementById("turbo-confirm");
  const focusTrap = createFocusTrap(dialog, {
    onActivate: () => dialog.classList.add("focus-trap"),
    onDeactivate: () => dialog.classList.remove("focus-trap"),
  });
  if (!dialog) {
    console.error(
      "Missing #turbo-confirm dialog. Please add it to your layout.",
    );
  }

  // Add any text that was passed in
  if (message) {
    dialog.querySelector("p").textContent = message;
  }

  // Save the default dialog content to reset when closing
  const defaultState = dialog.innerHTML;

  // Determine if custom content is provided
  // This can be hidden on a button inside a form created by rails
  const contentIdElement = element.querySelector("[data-turbo-content]");

  if (contentIdElement) {
    let contentId = contentIdElement.getAttribute("data-turbo-content");
    dialog.querySelector(".dialog--content").innerHTML =
      document.querySelector(contentId).innerHTML;
  }

  // See if there is a custom form to display
  const confirmValueElement = element.querySelector("[data-confirm-value]");
  if (confirmValueElement) {
    let value = confirmValueElement.getAttribute("data-confirm-value");
    const confirmForm = dialog.querySelector(".dialog--form--validate");
    confirmForm.setAttribute("data-confirmation-input-value", value);

    // Display the form to valid against value
    dialog.querySelector(".dialog--form").classList.add("hidden");
    confirmForm.classList.remove("hidden");
  }

  dialog.showModal();
  focusTrap.activate();

  return new Promise((resolve, reject) => {
    dialog.addEventListener(
      "close",
      () => {
        // Reset the dialog content
        dialog.innerHTML = defaultState;
        resolve(dialog.returnValue === "confirm");
        focusTrap.deactivate();
      },
      { once: true },
    );
  });
};
