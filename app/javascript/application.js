// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "flowbite";

import * as ActiveStorage from "@rails/activestorage";

import LocalTime from "local-time";

LocalTime.config.locale = document.documentElement.lang;
LocalTime.config.i18n["fr"] = {
  date: {
    dayNames: [
      "Dimanche",
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
    ],
    abbrDayNames: ["Dim.", "Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam."],
    monthNames: [
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre",
    ],
    abbrMonthNames: [
      "Janv.",
      "Févr.",
      "Mars",
      "Avr.",
      "Mai",
      "Juin",
      "Juil.",
      "Août",
      "Sept.",
      "Oct.",
      "Nov.",
      "Déc.",
    ],
    yesterday: "hier",
    today: "aujourd'hui",
    tomorrow: "demain",
    on: "un {date}",
    formats: {
      default: "%b %e, %Y",
      thisYear: "%b %e",
    },
  },
  time: {
    am: "am",
    pm: "pm",
    singular: "une {time}",
    singularAn: "une {time}",
    elapsed: "il y a {time}",
    second: "seconde",
    seconds: "secondes",
    minute: "minute",
    minutes: "minutes",
    hour: "heure",
    hours: "heures",
    formats: {
      default: "%H:%M",
      default_24h: "%H:%M",
    },
  },
  datetime: {
    at: "{date} à {time}",
    formats: {
      default: "%B %e, %Y à %H:%M %Z",
      default_24h: "%B %e, %Y à %H:%M %Z",
    },
  },
};

LocalTime.start();
ActiveStorage.start();

document.addEventListener("turbo:morph", () => {
  LocalTime.run();
});

Turbo.config.forms.confirm = (message, element) => {
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
      },
      { once: true },
    );
  });
};
