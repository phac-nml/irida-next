import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["system", "light", "dark"];

  connect() {
    let theme = localStorage.getItem("theme");
    if (theme === null || theme === "light") {
      this.lightTarget.checked = "checked";
    } else if (theme === "dark") {
      this.darkTarget.checked = "checked";
    } else {
      this.systemTarget.checked = "checked";
    }
  }

  toggleTheme(event) {
    const theme = event.target.value;
    localStorage.setItem("theme", theme);

    const isDarkMode =
      theme === "dark" ||
      (theme === "system" &&
        window.matchMedia("(prefers-color-scheme: dark)").matches);

    if (isDarkMode) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }
}
