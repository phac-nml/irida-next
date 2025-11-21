// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "./controllers";
import "flowbite";
import { createFocusTrap } from "focus-trap";

import * as ActiveStorage from "@rails/activestorage";
import LocalTimeModule from "local-time";

ActiveStorage.start();

// Make LocalTime globally available
window.LocalTime = LocalTimeModule;

// Configure LocalTime from meta tag data
function configureLocalTime() {
  const meta = document.querySelector('meta[name="local-time-i18n"]');
  if (!meta) return;

  const locale = meta.dataset.locale || document.documentElement.lang;
  const i18nData = meta.getAttribute('content');

  try {
    if (i18nData && i18nData !== '{}') {
      LocalTime.config.i18n[locale] = JSON.parse(i18nData);
    }
    LocalTime.config.locale = locale;
    LocalTime.start();
  } catch (error) {
    console.error('Failed to configure LocalTime:', error);
  }
}

// Configure on initial load
configureLocalTime();

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
  // Reconfigure LocalTime with updated locale and i18n data
  configureLocalTime();
  // ensure focused element is scrolled into view if out of view
  if (!isElementInViewport(document.activeElement)) {
    document.activeElement.scrollIntoView();
  }
});

document.addEventListener("turbo:before-stream-render", (event) => {
  const fallbackToDefaultActions = event.detail.render;

  event.detail.render = (streamElement) => {
    fallbackToDefaultActions(streamElement);

    // process new time elements added via turbo streams
    LocalTime.run();
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
