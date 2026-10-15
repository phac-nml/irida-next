import { Controller } from "@hotwired/stimulus";

// Host adapter for a standalone advanced search builder.
export default class AdvancedSearchStandaloneController extends Controller {
  static outlets = ["advanced-search--v2--builder"];

  connect() {
    this.renderBuilder();
  }

  advancedSearchV2BuilderOutletConnected() {
    this.renderBuilder();
  }

  renderBuilder() {
    if (this.hasAdvancedSearchV2BuilderOutlet) {
      this.advancedSearchV2BuilderOutlet.render();
    }
  }
}
