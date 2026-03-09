import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "trTemplate",
    "thTemplate",
    "tdTemplate",
    "sampleIdentifierTemplate",
    "dropdownTemplate",
    "fileTemplate",
    "metadataTemplate",
    "textInputTemplate",
    "samplesheetReadyTemplate",
    "paginationTemplate",
    "metadataHeaderForm",
  ];

  static outlets = ["nextflow--deferred-samplesheet"];

  cloneTemplate(templateName) {
    let templateTarget;
    switch (templateName) {
      case "trTemplate":
        templateTarget = this.trTemplateTarget;
        break;
      case "thTemplate":
        templateTarget = this.thTemplateTarget;
        break;
      case "tdTemplate":
        templateTarget = this.tdTemplateTarget;
        break;
      case "sampleIdentifierTemplate":
        templateTarget = this.sampleIdentifierTemplateTarget;
        break;
      case "dropdownTemplate":
        templateTarget = this.dropdownTemplateTarget;
        break;
      case "fileTemplate":
        templateTarget = this.fileTemplateTarget;
        break;
      case "metadataTemplate":
        templateTarget = this.metadataTemplateTarget;
        break;
      case "textInputTemplate":
        templateTarget = this.textInputTemplateTarget;
        break;
      case "samplesheetReadyTemplate":
        templateTarget = this.samplesheetReadyTemplateTarget;
        break;
      case "paginationTemplate":
        templateTarget = this.paginationTemplateTarget;
        break;
      case "metadataHeaderForm":
        templateTarget = this.metadataHeaderFormTarget;
        break;
    }

    return templateTarget.content.cloneNode(true);
  }
}
