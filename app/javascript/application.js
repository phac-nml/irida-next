// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "flowbite";
import { createFocusTrap } from "focus-trap";

import * as ActiveStorage from "@rails/activestorage";

ActiveStorage.start();

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
  LocalTime.config.locale = document.documentElement.lang;
  // reprocess each time element regardless if it has been already processed
  LocalTime.process(...document.querySelectorAll("time"));
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

// Fix for Turbo Drive back button navigation with lazy-loaded frames
//
// Problem: When navigating away from pages with lazy-loaded Turbo Frames, then
// clicking the browser back button, Turbo sometimes fails to restore the page
// from cache, resulting in a silent failure where the URL updates but the page
// content doesn't change.
//
// Solution: Listen for popstate events (back/forward button) and detect if the
// page failed to load by checking for unprocessed lazy Turbo Frames. If found,
// force a proper Turbo visit to reload the page.
//
// This works for any page with lazy-loaded frames, not just specific URLs.
let currentUrl = window.location.href;

// Update currentUrl on every Turbo navigation
document.addEventListener("turbo:load", () => {
  currentUrl = window.location.href;
});

// Listen for browser back/forward button
window.addEventListener("popstate", () => {
  const newUrl = window.location.href;

  // Skip if URL didn't actually change
  if (currentUrl === newUrl) return;

  currentUrl = newUrl;

  // Give Turbo a moment to try its own navigation
  setTimeout(() => {
    // Check if there are lazy-loaded turbo-frames with src attributes
    // If they still have src after the timeout, it means they weren't loaded
    // (when Turbo properly loads a page, lazy frames fetch and clear their src)
    const unloadedFrames = document.querySelectorAll(
      'turbo-frame[loading="lazy"][src]',
    );

    // If we found unloaded frames, Turbo failed to navigate properly
    if (unloadedFrames.length > 0 && window.Turbo) {
      window.Turbo.visit(newUrl, { action: "replace" });
    }
  }, 100);
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
