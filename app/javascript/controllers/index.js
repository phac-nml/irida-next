// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application";

// Eager load all controllers defined in the import map under controllers/**/*_controller
// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

// eagerLoadControllersFrom("controllers", application);

// Register Pathogen controllers before lazy loading (prevents auto-load conflicts)
import { registerPathogenControllers } from "pathogen_view_components";
registerPathogenControllers(application);

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading";

lazyLoadControllersFrom("controllers", application);
