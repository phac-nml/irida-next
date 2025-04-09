import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["system", "light", "dark"];

  connect() {
    let theme = localStorage.getItem("theme");
    if (theme === "light") {
      this.lightTarget.checked = "checked";
    } else if (theme === "dark") {
      this.darkTarget.checked = "checked";
    } else {
      // no setting or value set to "system"
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
      document.documentElement.classList.remove("light");
    } else {
      document.documentElement.classList.add("light");
      document.documentElement.classList.remove("dark");
    }
  }
}
