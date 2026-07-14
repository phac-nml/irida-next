const DESKTOP_BREAKPOINT = "(min-width: 80rem)";

function initializeActiveAdminNavigation() {
  const navigation = document.querySelector(
    'nav[data-controller="active-admin-navigation"]',
  );
  const menu = navigation?.querySelector("#main-menu");
  if (!menu) return;

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

initializeActiveAdminNavigation();
