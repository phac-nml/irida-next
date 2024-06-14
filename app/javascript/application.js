// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import * as ActiveStorage from "@rails/activestorage";
ActiveStorage.start();

Turbo.setConfirmMethod((message, element) => {
  console.log(element);
  const dialog = document.getElementById("turbo-confirm");
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

  return new Promise((resolve, reject) => {
    dialog.addEventListener(
      "close",
      () => {
        // Reset the dialog content
        dialog.innerHTML = defaultState;
        resolve(dialog.returnValue === "confirm");

        if (dialog.returnValue === "confirm") {
          // Check to see if there is a callback to run
          const callbackEl = element.querySelector("[data-turbo-callback]");
          if (callbackEl) {
            const callback = callbackEl.getAttribute("data-turbo-callback");
            eval(callback);
          }
          resolve(true);
        } else {
          resolve(false);
        }

        // remove listeners
        dialog.removeEventListener("close", () => {});
      },
      { once: true },
    );
  });
});
