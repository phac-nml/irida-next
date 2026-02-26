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

  // createClone(templateName) {
  //   clonedNode;
  //   switch (templateName) {
  //     case value1:
  //       // Code to execute if expression === value1
  //       break;
  //     case value2:
  //       // Code to execute if expression === value2
  //       break;
  //     default:
  //     // Code to execute if none of the cases match
  //   }
  // }

  // #cloneTemplate(template) {
  //   return template.content.cloneNode(true);
  // }
}
