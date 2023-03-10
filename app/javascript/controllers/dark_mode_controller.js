import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["lightIcon", "darkIcon", "themeToggle"];

  connect() {
    if (
      localStorage.getItem("theme") === "dark" ||
      (!("theme" in localStorage) &&
        window.matchMedia("(prefers-color-scheme: dark)").matches)
    ) {
      this.lightIconTarget.classList.remove("hidden");
    } else {
      this.darkIconTarget.classList.remove("hidden");
    }
  }

  toggleTheme() {
    this.lightIconTarget.classList.toggle("hidden");
    this.darkIconTarget.classList.toggle("hidden");

    if (localStorage.getItem("theme")) {
      if (localStorage.getItem("theme") === "light") {
        document.documentElement.classList.add("dark");
        localStorage.setItem("theme", "dark");
      } else {
        document.documentElement.classList.remove("dark");
        localStorage.setItem("theme", "light");
      }

      // if NOT set via local storage previously
    } else {
      if (document.documentElement.classList.contains("dark")) {
        document.documentElement.classList.remove("dark");
        localStorage.setItem("theme", "light");
      } else {
        document.documentElement.classList.add("dark");
        localStorage.setItem("theme", "dark");
      }
    }
  }
}
