// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

Turbo.setConfirmMethod((message, element) => {
  const dialog = document.getElementById("turbo-confirm");
  if (!dialog) {
    console.error(
      "Missing #turbo-confirm dialog. Please add it to your layout."
    );
  }

  // Save the default dialog content to reset when closing
  const defaultState = dialog.innerHTML;

  // Determine if custom content is provided
  const contentIdElement = element.querySelector("[data-turbo-content]");

  if (contentIdElement) {
    let contentId = contentIdElement.getAttribute("data-turbo-content");
    dialog.querySelector(".dialog--content").innerHTML =
      document.querySelector(contentId).innerHTML;
  } else {
    dialog.querySelector("p").textContent = message;
  }

  // See if there is a custom form to display
  const formIdElement = element.querySelector("[data-turbo-form]");
  if (formIdElement) {
    let formId = formIdElement.getAttribute("data-turbo-form");
    dialog.querySelector(".dialog--form").innerHTML =
      document.querySelector(formId).innerHTML;
  }

  dialog.showModal();

  return new Promise((resolve, reject) => {
    dialog.addEventListener(
      "close",
      () => {
        // Reset the dialog content
        dialog.innerHTML = defaultState;
        resolve(dialog.returnValue === "confirm");
      },
      { once: true }
    );
  });
});
