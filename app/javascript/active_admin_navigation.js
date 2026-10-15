const DESKTOP_BREAKPOINT = "(min-width: 80rem)";
const INITIALIZED_ATTRIBUTE = "data-active-admin-navigation-initialized";

function initializeActiveAdminNavigation() {
  const navigation = document.querySelector(
    "nav[data-active-admin-navigation]",
  );
  if (!navigation || navigation.hasAttribute(INITIALIZED_ATTRIBUTE)) return;
  const menu = navigation?.querySelector("#main-menu");
  if (!menu) return;

  navigation.setAttribute(INITIALIZED_ATTRIBUTE, "true");

  const desktop = window.matchMedia(DESKTOP_BREAKPOINT);
  const sync = () => {
    const hidden =
      !desktop.matches && menu.classList.contains("-translate-x-full");

    navigation.inert = hidden;
    menu.toggleAttribute("aria-hidden", hidden);
  };

  const observer = new MutationObserver(sync);
  observer.observe(menu, {
    attributes: true,
    attributeFilter: ["aria-hidden", "class"],
  });
  desktop.addEventListener("change", sync);

  sync();
}

document.addEventListener("turbo:load", initializeActiveAdminNavigation);
if (document.readyState === "loading") {
  document.addEventListener(
    "DOMContentLoaded",
    initializeActiveAdminNavigation,
    {
      once: true,
    },
  );
} else {
  initializeActiveAdminNavigation();
}
