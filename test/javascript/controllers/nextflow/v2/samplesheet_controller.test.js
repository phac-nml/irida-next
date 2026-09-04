import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import SamplesheetController from "../../../../../app/javascript/controllers/nextflow/v2/samplesheet_controller.js";
import SelectionController from "../../../../../app/javascript/controllers/selection_controller.js";

const setupStandardSamplesheetAttributes = (samples) => {
  renderFullFixture();

  const sampleAttributesContainer =
    document.getElementById("sample_attributes");

  if (!sampleAttributesContainer) {
    throw new Error("Missing #sample_attributes fixture");
  }

  sessionStorage.setItem("selection-test-key", createSampleIds(samples));

  sampleAttributesContainer.insertAdjacentHTML(
    "afterbegin",
    `<div
      class="hidden"
      data-nextflow--v2--samplesheet-target="sampleAttributes"
      data-allowed-to-update-samples="true"
      data-sample-attributes='${createSampleAttributes(samples)}'
    ></div>
    <div
      class="hidden"
      data-nextflow--v2--samplesheet-target="fileAttributes"
    >
      ${createFileAttributes(samples)}
    </div>`,
  );
};

const range = (start, end) =>
  Array.from({ length: end - start + 1 }, (_, i) => start + i);

const createSampleIds = (samples) => {
  return JSON.stringify(samples.map((n) => `sample-${n}-id`));
};

const createSampleAttributes = (samples) => {
  return JSON.stringify(
    Object.fromEntries(
      samples.map((n) => [
        `sample-${n}-id`,
        {
          sample_id: `sample-${n}-id`,
          samplesheet_params: {
            sample: `SAMPLE-PUID-${n}`,
            fastq_1: `gid://irida/Attachment/sample-${n}-fastq-1`,
            fastq_2: `gid://irida/Attachment/sample-${n}-fastq-2`,
            metadata_1: "",
            sample_name: `SAMPLE NAME ${n}`,
            fastmatch_category: "",
            an_input_cell: "",
          },
        },
      ]),
    ),
  );
};

const createFileAttributes = (samples) => {
  return JSON.stringify(
    Object.fromEntries(
      samples.map((n) => [
        `sample-${n}-id`,
        {
          fastq_1: {
            filename: `sample_${n}_fastq_1.fastq.gz`,
            attachment_id: `sample-${n}-fastq-1-id`,
          },
          fastq_2: {
            filename: `sample_${n}_fastq_2.fastq.gz`,
            attachment_id: `sample-${n}-fastq-2-id`,
          },
        },
      ]),
    ),
  );
};

// verify the expectedSamples exist on the table, with their respective files, and all other samples do not exist
const assertTableData = (allSamples, expectedSamples) => {
  const tableBody = document.querySelector(
    '[data-nextflow--v2--samplesheet-target="tableBody"]',
  );

  const getCellValue = (cell) => {
    const control = cell.querySelector("input, select");
    if (control) {
      return control.value.trim();
    }
    return cell.textContent.trim();
  };

  const rows = [...tableBody.querySelectorAll("tr")].map((row) =>
    [...row.querySelectorAll("th, td")].map(getCellValue),
  );

  const expectedRows = expectedSamples.map((n) => [
    `SAMPLE-PUID-${n}`,
    `SAMPLE NAME ${n}`,
    "", // empty text input for metadata
    `sample_${n}_fastq_1.fastq.gz`,
    `sample_${n}_fastq_2.fastq.gz`,
    "", // empty select option value for dropdown
    "",
  ]);

  expect(rows).toEqual(expectedRows);

  const displayedValues = rows.flat();

  allSamples
    .filter((n) => !expectedSamples.includes(n))
    .forEach((n) => {
      expect(displayedValues).not.toContain(`SAMPLE-PUID-${n}`);
      expect(displayedValues).not.toContain(`SAMPLE NAME ${n}`);
      expect(displayedValues).not.toContain(`sample-${n}-id_metadata_1`);
      expect(displayedValues).not.toContain(`sample_${n}_fastq_1.fastq.gz`);
      expect(displayedValues).not.toContain(`sample_${n}_fastq_2.fastq.gz`);
    });
};

// using getter functions as we will need to re-query these items throughout tests and state changes
const getPreviousBtn = () =>
  document.querySelector(
    '[data-nextflow--v2--samplesheet-target="previousBtn"]',
  );
const getNextBtn = () =>
  document.querySelector('[data-nextflow--v2--samplesheet-target="nextBtn"]');
const getPageNum = () =>
  document.querySelector('[data-nextflow--v2--samplesheet-target="pageNum"]');

const assertPaginationState = (previousDisabled, nextDisabled, currentPage) => {
  expect(getPreviousBtn().disabled).toBe(previousDisabled);
  expect(getNextBtn().disabled).toBe(nextDisabled);
  expect(getPageNum().value).toBe(currentPage);
};

const assertPaginationOptions = (expectedPresent, expectedAbsent = []) => {
  const values = [...getPageNum().options].map((option) => option.value);

  expectedPresent.forEach((value) => {
    expect(values).toContain(value);
  });

  expectedAbsent?.forEach((value) => {
    expect(values).not.toContain(value);
  });
};

const applyFilter = async (value) => {
  const filter = document.querySelector("#samplesheet-filter");
  filter.value = value;

  filter.dispatchEvent(
    new KeyboardEvent("keydown", {
      key: "Enter",
      code: "Enter",
      bubbles: true,
    }),
  );

  vi.advanceTimersByTime(60);
};

function renderFullFixture() {
  renderBaseFixture();
  renderSamplesheetProperties();
  renderTable();
  renderTemplates();
  renderSelectionOutlet();
}

/* eslint-disable no-useless-escape */
function renderSamplesheetProperties() {
  const samplesheet = document.getElementById("samplesheet");
  samplesheet.insertAdjacentHTML(
    "afterbegin",
    `<div
          class="hidden"
          data-nextflow--v2--samplesheet-target="samplesheetProperties"
          data-properties="{&quot;sample&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;pattern&quot;:&quot;^\\\\S+$&quot;,&quot;meta&quot;:[&quot;irida_id&quot;],&quot;unique&quot;:true,&quot;errorMessage&quot;:&quot;Sample name must be provided and cannot contain spaces.&quot;,&quot;required&quot;:true,&quot;cell_type&quot;:&quot;sample_cell&quot;},&quot;sample_name&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;meta&quot;:[&quot;id&quot;],&quot;errorMessage&quot;:&quot;Sample name is optional, if provided will replace sample for filenames and outputs&quot;,&quot;required&quot;:false,&quot;cell_type&quot;:&quot;sample_name_cell&quot;,&quot;pattern&quot;:null},&quot;metadata_1&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;meta&quot;:[&quot;metadata_1&quot;],&quot;errorMessage&quot;:&quot;Metadata associated with the sample (metadata_1).&quot;,&quot;default&quot;:&quot;&quot;,&quot;pattern&quot;:&quot;^[^\\\\n\\\\t\\\&quot;]+$&quot;,&quot;required&quot;:false,&quot;cell_type&quot;:&quot;metadata_cell&quot;},&quot;fastq_1&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;format&quot;:&quot;file-path&quot;,&quot;exists&quot;:true,&quot;pattern&quot;:&quot;^([\\\\S\\\\s]*\\\\/)?[^\\\\s\\\\/]+\\\\.f(ast)?q\\\\.gz$&quot;,&quot;errorMessage&quot;:&quot;FastQ file for reads 1 must be provided, cannot contain spaces and must have extension '.fq.gz' or '.fastq.gz'&quot;,&quot;required&quot;:true,&quot;cell_type&quot;:&quot;fastq_cell&quot;,&quot;autopopulate&quot;:true},&quot;fastq_2&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;format&quot;:&quot;file-path&quot;,&quot;exists&quot;:true,&quot;pattern&quot;:&quot;^([\\\\S\\\\s]*\\\\/)?[^\\\\s\\\\/]+\\\\.f(ast)?q\\\\.gz$&quot;,&quot;errorMessage&quot;:&quot;FastQ file for reads 2 cannot contain spaces and must have extension '.fq.gz' or '.fastq.gz'&quot;,&quot;required&quot;:true,&quot;cell_type&quot;:&quot;fastq_cell&quot;,&quot;autopopulate&quot;:true},&quot;fastmatch_category&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;errorMessage&quot;:&quot;Has to be either query or reference&quot;,&quot;cell_type&quot;:&quot;dropdown_cell&quot;,&quot;enum&quot;:[&quot;query&quot;,&quot;reference&quot;]},&quot;an_input_cell&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;default&quot;:&quot;&quot;,&quot;required&quot;:false,&quot;cell_type&quot;:&quot;input_cell&quot;}}"
        ></div>`,
  );
}
/* eslint-enable no-useless-escape */

function renderFilter() {
  const filterContainer = document.getElementById("data-test-filter-container");
  filterContainer.insertAdjacentHTML(
    "afterbegin",
    `<label for="samplesheet-filter">
              Search by PUID or name
            </label>

            <input id="samplesheet-filter" data-nextflow--v2--samplesheet-target="filter" data-action="keydown.enter-&gt;nextflow--v2--samplesheet#filter" type="search" placeholder="Search by PUID or name" autocomplete="off">

            <button data-nextflow--v2--samplesheet-target="filterClearButton" class="hidden" data-action="click-&gt;nextflow--v2--samplesheet#clearFilter" type="button" aria-label="Clear search">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
                <rect width="256" height="256" fill="none"></rect>
                <line x1="200" y1="56" x2="56" y2="200" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
                <line x1="200" y1="200" x2="56" y2="56" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
              </svg>
            </button>

            <button data-nextflow--v2--samplesheet-target="filterSearchButton" data-action="click-&gt;nextflow--v2--samplesheet#filter" type="button" aria-label="Search">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
                <rect width="256" height="256" fill="none"></rect>
                <circle cx="112" cy="112" r="80" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></circle>
                <line x1="168.57" y1="168.57" x2="224" y2="224" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
              </svg>
            </button>`,
  );
}

function renderTable() {
  const tableContainer = document.getElementById("data-test-table-container");
  tableContainer.insertAdjacentHTML(
    "afterbegin",
    ` <table data-test-selector="samplesheet-table" data-controller="table" data-action="focusin-&gt;table#handleCellFocus">
              <thead>
                <tr>
                  <th>
                    <div>
                      sample
                      <span>
                        (Required)
                      </span>
                    </div>
                  </th>

                  <th>
                    <div>
                      sample_name
                    </div>
                  </th>

                  <th>
                    <label for="field-metadata_1">metadata_1</label>

                    <select
                      class="metadata_field-header"
                      name="field"
                      id="field-metadata_1"
                      data-action="change-&gt;nextflow--v2--samplesheet#handleMetadataSelection"
                      data-metadata-header="metadata_1"
                    >
                      <option value="" label=" "></option>
                      <option selected="selected" value="metadata_1">metadata_1 (default)</option>
                      <option value="WGS_id">WGS_id</option>
                      <option value="age">age</option>
                      <option value="country">country</option>
                      <option value="earliest_date">earliest_date</option>
                      <option value="food">food</option>
                      <option value="gender">gender</option>
                      <option value="insdc_accession">insdc_accession</option>
                      <option value="ncbi_accession">ncbi_accession</option>
                      <option value="onset">onset</option>
                      <option value="patient_age">patient_age</option>
                      <option value="patient_sex">patient_sex</option>
                    </select>
                  </th>

                  <th>
                    <div>
                      fastq_1
                      <span>
                        (Required)
                      </span>
                    </div>
                  </th>

                  <th>
                    <div>
                      fastq_2
                    </div>
                  </th>
                </tr>
              </thead>

              <tbody data-nextflow--v2--samplesheet-target="tableBody">
              </tbody>
            </table>`,
  );
}

function renderTemplates() {
  const samplesheetContainer = document.getElementById(
    "data-test-samplesheet-container",
  );
  samplesheetContainer.insertAdjacentHTML(
    "afterbegin",
    `<template data-nextflow--v2--samplesheet-target="trTemplate">
        <tr></tr>
      </template>

      <template data-nextflow--v2--samplesheet-target="thTemplate">
        <th></th>
      </template>

      <template data-nextflow--v2--samplesheet-target="tdTemplate">
        <td></td>
      </template>

      <template data-nextflow--v2--samplesheet-target="sampleIdentifierTemplate">
        <div></div>
      </template>

      <template data-nextflow--v2--samplesheet-target="dropdownTemplate">
        <select data-action="change-&gt;nextflow--v2--samplesheet#updateEditableSamplesheetData">
          <option value="" label=" "></option>
        </select>
      </template>

      <template data-nextflow--v2--samplesheet-target="fileTemplate">
        <a href="/-/workflow_executions/file_selector/new" data-base-path="/-/workflow_executions/file_selector/new" data-turbo-stream="true" data-namespace-id="b3d29210-cefc-4b22-ad8e-c44c332b6c40"></a>
      </template>

      <template data-nextflow--v2--samplesheet-target="metadataTemplate">
        <div><span></span></div>
      </template>

      <template data-nextflow--v2--samplesheet-target="textInputTemplate">
        <label></label>
        <input data-action="change-&gt;nextflow--v2--samplesheet#updateEditableSamplesheetData" type="text" autocomplete="off">
      </template>

      <template data-nextflow--v2--samplesheet-target="paginationTemplate">
        <nav aria-label="Pagination Navigation">
          <ul>
            <li>
              <button type="button" data-action="click-&gt;nextflow--v2--samplesheet#previousPage" data-nextflow--v2--samplesheet-target="previousBtn" disabled="">
                Previous
              </button>
            </li>

            <li>
              <label for="pagination-page-selector">
                Pagination page selector
              </label>

              <select data-nextflow--v2--samplesheet-target="pageNum" data-action="change-&gt;nextflow--v2--samplesheet#pageSelected" id="pagination-page-selector">
                <option value="1" selected="">1</option>
              </select>
            </li>

            <li>
              <button type="button" data-nextflow--v2--samplesheet-target="nextBtn" data-action="click-&gt;nextflow--v2--samplesheet#nextPage" disabled="">
                Next
              </button>
            </li>
          </ul>
        </nav>
      </template>

      <template data-nextflow--v2--samplesheet-target="metadataHeaderForm">
        <form action="/-/workflow_executions/metadata/fields" accept-charset="UTF-8" method="post">
          <input type="hidden" name="authenticity_token" value="nmzk_Fz82ZdmFqaMt7hu-6a0Bcp20H9nOfz8A9JDHUS7wUPV8FVsfHMx9HMPDlhdRC7HqFqadZ_bbvg_uFvmQg">
          <input value="a_namespace_id" type="hidden" name="namespace_id" id="namespace_id">
        </form>
      </template>`,
  );
}

function renderSelectionOutlet() {
  document.body.insertAdjacentHTML(
    "beforeend",
    `  <div
    hidden
    id="samples-table"
    data-controller="selection"
    data-selection-storage-key-value="selection-test-key"
    data-selection-max-selection-value="1000"
    data-selection-limit-message-value="test limit message"
    data-selection-storage-limit-message-value="test storage limit message"
  ></div>`,
  );
}

function renderMetadataParamsHeader() {
  document.body.insertAdjacentHTML(
    "beforeend",
    `<div>
  <span>
    --metadata_1_header
  </span>
  <input
    placeholder=""
    value="metadata_1"
    pattern="^[^\n\t&quot;]+$"
    data-metadata-header-name="metadata_1"
    type="text"
    name="workflow_execution[workflow_params][metadata_1_header]"
    id="workflow_execution_workflow_params_metadata_1_header"
  >
</div>`,
  );
}

/* eslint-disable no-useless-escape */
function renderBaseFixture() {
  document.body.innerHTML = `
    <div id="nextflow-container" data-controller="nextflow--v2--samplesheet" data-nextflow--v2--samplesheet-data-missing-error-value="The following samples are missing required data: " data-nextflow--v2--samplesheet-url-value="/-/workflow_executions" data-nextflow--v2--samplesheet-workflow-value="{&quot;name&quot;:&quot;phac-nml/iridanextexample&quot;,&quot;version&quot;:&quot;1.0.3&quot;}" data-nextflow--v2--samplesheet-no-selected-file-value="No selected file" data-nextflow--v2--samplesheet-form-error-value="Please review the following problems:" data-nextflow--v2--samplesheet-automated-workflow-value="false" data-nextflow--v2--samplesheet-name-missing-value="Name is required. Please enter a name for the workflow execution." data-nextflow--v2--samplesheet-allowed-to-update-samples-string-value="Update samples with analysis results" data-nextflow--v2--samplesheet-not-allowed-to-update-samples-string-value="You are not authorized to update samples with analysis results" data-nextflow--v2--samplesheet-processing-error-value="An error has occurred while processing your request. Please re-launch the workflow execution. If the issue persists, de-select and re-select the samples." data-nextflow--v2--samplesheet-loading-complete-announcement-value="Samplesheet is ready." data-nextflow--v2--samplesheet-selection-outlet="#samples-table" data-controller-connected="true">
  <h1>
    phac-nml/iridanextexample
  </h1>

  <p>IRIDA Next Example Pipeline</p>
  <turbo-frame id="workflow_execution_errors"></turbo-frame>

  <div role="alert" aria-live="assertive" aria-atomic="true" data-nextflow--v2--samplesheet-target="formFieldError">
    <div>
      <div>
        <div data-nextflow--v2--samplesheet-target="formFieldErrorMessage"></div>
      </div>
    </div>
  </div>

  <form data-turbo-frame="_top" data-nextflow--v2--samplesheet-target="form" action="/-/workflow_executions" accept-charset="UTF-8" method="post">
    <input type="hidden" name="authenticity_token" value="authenticity_token_value">
    <input type="hidden" name="format" id="submission_turbo" value="turbo_stream">

    <section>
      <div id="workflow_execution_name_field">
        <label for="workflow_execution_name">
          Name <abbr class="req" title="required" aria-hidden="true">*</abbr>
        </label>

        <input aria-required="true" type="text" name="workflow_execution[name]" id="workflow_execution_name">

        <div id="workflow_execution_name_error">
          <span class="hidden">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" aria-hidden="true">
              <rect width="256" height="256" fill="none"></rect>
              <line x1="160" y1="96" x2="96" y2="160" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
              <line x1="96" y1="96" x2="160" y2="160" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
              <circle cx="128" cy="128" r="96" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></circle>
            </svg>
            <span class="grow"></span>
          </span>
        </div>

        <p id="workflow_execution_name_hint">
          A custom name will make it easier to search for this in the future.
        </p>
      </div>
    </section>

    <input value="a_namespace_id" type="hidden" name="workflow_execution[namespace_id]" id="workflow_execution_namespace_id">

    <input value="phac-nml/iridanextexample" type="hidden" name="workflow_execution[metadata][pipeline_id]" id="workflow_execution_metadata_pipeline_id">
    <input value="1.0.3" type="hidden" name="workflow_execution[metadata][workflow_version]" id="workflow_execution_metadata_workflow_version">

    <h2>Input/output options</h2>
    <p>Define where the pipeline should find input data and save output data.</p>

    <div id="data-test-samplesheet-container">
      <div id="samplesheet_message" data-nextflow--v2--samplesheet-target="samplesheetMessagesContainer"></div>

      <div id="samplesheet">
        <turbo-frame id="sample_attributes"></turbo-frame>

        <div>
          <label>
            Samples (5)
          </label>

          <div id="data-test-filter-container">
          </div>
        </div>

        <div role="alert" aria-live="assertive" aria-atomic="true" data-nextflow--v2--samplesheet-target="error">
          <div>
            <div>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
                <rect width="256" height="256" fill="none"></rect>
                <line x1="160" y1="96" x2="96" y2="160" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
                <line x1="96" y1="96" x2="160" y2="160" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
                <circle cx="128" cy="128" r="96" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></circle>
              </svg>
            </div>

            <div>
              <div data-nextflow--v2--samplesheet-target="errorMessage"></div>
            </div>
          </div>
        </div>

        <div>
          <div id="data-test-table-container">
          </div>
        </div>

        <div data-nextflow--v2--samplesheet-target="emptyState" class="hidden">
          <section role="status" aria-labelledby="empty-state-title-1568576" aria-describedby="empty-state-desc-1568576">
            <div aria-hidden="true">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
                <rect width="256" height="256" fill="none"></rect>
                <circle cx="128" cy="128" r="96" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></circle>
              </svg>
            </div>

            <h2 id="empty-state-title-1568576">
              No items found
            </h2>

            <div id="empty-state-desc-1568576">
              <span>No items found matching your search</span>
            </div>
          </section>
        </div>

        <div data-nextflow--v2--samplesheet-target="paginationContainer"></div>
        <turbo-frame id="samplesheet-payload-container"></turbo-frame>
      </div>


      <div class="flex justify-center" id="samplesheet-spinner" data-nextflow--v2--samplesheet-target="samplesheetSpinner">
                    <div class="
                        flex w-full max-w-xs items-center space-x-2 rounded-lg bg-white p-4 text-gray-500
                        rtl:space-x-reverse rtl:divide-x-reverse dark:divide-gray-700 dark:bg-gray-800
                        dark:text-gray-400
                      ">
                      <svg xmlns="http://www.w3.org/2000/svg" stroke-width="4" viewBox="0 0 24 24" class="text-primary-600 dark:text-primary-500 fill-primary-600 dark:fill-primary-500 size-6 faded-spinner-icon"><style>@keyframes spin{to{transform:rotate(360deg)}}</style>
<g style="transform-origin:center;animation:spin 1s linear infinite"><circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" style="opacity:.25"></circle><path fill="none" stroke="currentColor" stroke-linecap="round" d="M12 2a10 10 0 0 1 10 10" style="opacity:.75"></path></g></svg>

                      <span class="text-sm font-normal">
                        Processing samplesheet
                      </span>
                    </div>
                  </div>
      <div>
        <label for="workflow_execution_workflow_params_project_name">
          The name of the project.
        </label>
        <div>
          <span>
            --project_name
          </span>
          <input placeholder="" value="assembly" pattern="^\S+$" type="text" name="workflow_execution[workflow_params][project_name]" id="workflow_execution_workflow_params_project_name">
        </div>
      </div>

      <div>
        <label for="workflow_execution_workflow_params_assembler">
          The sequence assembler to use for sequence assembly.
        </label>
        <div>
          <span>
            --assembler
          </span>
          <select name="workflow_execution[workflow_params][assembler]" id="workflow_execution_workflow_params_assembler">
            <option value="default">default</option>
            <option selected="selected" value="stub">stub</option>
            <option value="experimental">experimental</option>
          </select>
        </div>
      </div>

      <div>
        <label for="workflow_execution_workflow_params_random_seed">
          The random seed to use for sequence assembly.
        </label>
        <div>
          <span>
            --random_seed
          </span>
          <input placeholder="" value="1" type="text" name="workflow_execution[workflow_params][random_seed]" id="workflow_execution_workflow_params_random_seed">
        </div>
      </div>
    </div>

    <div class="mb-4 flex" id="update-samples-spinner" data-nextflow--v2--samplesheet-target="updateSamplesSpinner">
          <div class="
              flex w-full items-center space-x-2 rounded-lg bg-white pr-4 text-gray-500 rtl:space-x-reverse
              rtl:divide-x-reverse dark:divide-gray-700 dark:bg-gray-800 dark:text-gray-400
            " role="alert">
            <svg xmlns="http://www.w3.org/2000/svg" stroke-width="4" viewBox="0 0 24 24" class="text-primary-600 dark:text-primary-500 fill-primary-600 dark:fill-primary-500 size-6 faded-spinner-icon"><style>@keyframes spin{to{transform:rotate(360deg)}}</style>
<g style="transform-origin:center;animation:spin 1s linear infinite"><circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" style="opacity:.25"></circle><path fill="none" stroke="currentColor" stroke-linecap="round" d="M12 2a10 10 0 0 1 10 10" style="opacity:.75"></path></g></svg>

            <span class="text-sm font-medium text-slate-900 dark:text-white">
              Verifying if you're authorized to update samples with analysis results
            </span>
          </div>
        </div>
<div class="hidden" aria-hidden="true">
          <input name="workflow_execution[update_samples]" type="hidden" value="0"><input data-nextflow--v2--samplesheet-target="updateSamplesCheckbox" type="checkbox" value="1" name="workflow_execution[update_samples]" id="workflow_execution_update_samples">

          <label for="workflow_execution_update_samples" data-nextflow--v2--samplesheet-target="updateSamplesLabel"></label>
        </div>
    <div>
      <input name="workflow_execution[email_notification]" type="hidden" value="0">
      <input type="checkbox" value="1" name="workflow_execution[email_notification]" id="workflow_execution_email_notification">

      <label for="workflow_execution_email_notification">Receive an email notification when your analysis has completed?</label>
    </div>

    <div>
      <input name="workflow_execution[shared_with_namespace]" type="hidden" value="0">
      <input type="checkbox" value="1" name="workflow_execution[shared_with_namespace]" id="workflow_execution_shared_with_namespace">

      <label for="workflow_execution_shared_with_namespace">Share results with group members?</label>
    </div>

    <button data-nextflow--v2--samplesheet-target="submit" type="button" data-action="click-&gt;nextflow--v2--samplesheet#submitSamplesheet">
      Submit
    </button>
  </form>

  <div data-nextflow--v2--samplesheet-target="submissionSpinner">
    <div id="nextflow-processing-request-spinner">
      <div>
        <div role="alert">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
            <style>@keyframes spin{to{transform:rotate(360deg)}}</style>
            <g>
              <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor"></circle>
              <path fill="none" stroke="currentColor" stroke-linecap="round" d="M12 2a10 10 0 0 1 10 10"></path>
            </g>
          </svg>

          <span id="nextflow-processing-request-spinner-message">
            Processing your submission, this may take some time.
          </span>
        </div>
      </div>
    </div>
  </div>

  <template data-nextflow--v2--samplesheet-target="samplesheetParamsFormTemplate">
    <form action="/-/workflow_executions/submissions/samplesheet" accept-charset="UTF-8" method="post">
      <input type="hidden" name="authenticity_token" value="an_authenticity_token">
    </form>
  </template>

  <div aria-live="assertive" data-nextflow--v2--samplesheet-target="ariaLive">Samplesheet is ready.</div>

  <template data-nextflow--v2--samplesheet-target="samplesheetReadyTemplate">
    <div data-controller="viral--alert" data-viral--alert-dismissible-value="true" data-viral--alert-auto-dismiss-value="true" data-viral--alert-type-value="success" data-viral--alert-alert-id-value="alert-success-1568584" data-viral--alert-dismiss-button-id-value="alert-success-1568584-dismiss" data-viral--alert-auto-dismiss-duration-value="10000" data-viral--alert-announce-alert-value="false" data-viral--alert-dismissed-text-value="Alert dismissed">
      <div>
        <div>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
            <rect width="256" height="256" fill="none"></rect>
            <polyline points="88 136 112 160 168 104" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></polyline>
            <circle cx="128" cy="128" r="96" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></circle>
          </svg>
        </div>

        <div>
          <div>
            <div>(Complete) Preparing workflow execution arguments for 5 samples, this may take a bit of time.</div>
            <div>Samplesheet is ready.</div>
          </div>
        </div>

        <div>
          <button type="button" id="alert-success-1568584-dismiss" data-action="viral--alert#dismiss" aria-label="Close">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
              <rect width="256" height="256" fill="none"></rect>
              <line x1="200" y1="56" x2="56" y2="200" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
              <line x1="200" y1="200" x2="56" y2="56" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
            </svg>
            <span>Close</span>
          </button>
        </div>
      </div>

      <div data-viral--alert-target="progressBar"></div>
    </div>
  </template>
</div>
  `;
}
/* eslint-enable no-useless-escape */

async function startController() {
  const application = Application.start();
  application.register("nextflow--v2--samplesheet", SamplesheetController);
  application.register("selection", SelectionController);
  await Promise.resolve();
  return application;
}

describe("nextflow v2 samplesheet controller", () => {
  let application;

  beforeEach(() => {
    window.requestAnimationFrame = (callback) => setTimeout(callback, 0);
    localStorage.clear();
    Element.prototype.scrollIntoView = vi.fn();
    vi.useFakeTimers();
  });

  afterEach(() => {
    application?.stop();
    vi.useRealTimers();
  });

  it("no pagination with 5 samples", async () => {
    setupStandardSamplesheetAttributes(range(1, 5));
    application = await startController();

    expect(
      document.querySelector(
        '[data-nextflow--v2--samplesheet-target="previousBtn"]',
      ),
    ).toBeNull();

    expect(
      document.querySelector(
        '[data-nextflow--v2--samplesheet-target="pageNum"]',
      ),
    ).toBeNull();

    expect(
      document.querySelector(
        '[data-nextflow--v2--samplesheet-target="nextBtn"]',
      ),
    ).toBeNull();
  });

  it("pagination change states", async () => {
    const allSamples = range(1, 11);
    setupStandardSamplesheetAttributes(allSamples);
    application = await startController();

    expect(getPreviousBtn()).not.toBeNull();
    expect(getPageNum()).not.toBeNull();
    expect(getNextBtn()).not.toBeNull();
    assertPaginationOptions(["1", "2", "3"]);

    assertPaginationState(true, false, "1");
    assertTableData(allSamples, range(1, 5));

    // change pages by clicking next/previous buttons
    getNextBtn().click();

    assertPaginationState(false, false, "2");
    assertTableData(allSamples, range(6, 10));

    getNextBtn().click();

    assertPaginationState(false, true, "3");
    assertTableData(allSamples, [11]);

    getPreviousBtn().click();

    assertPaginationState(false, false, "2");
    assertTableData(allSamples, range(6, 10));

    getPreviousBtn().click();

    assertPaginationState(true, false, "1");
    assertTableData(allSamples, range(1, 5));

    // change pages using select dropdown
    getPageNum().value = "2";
    getPageNum().dispatchEvent(new Event("change", { bubbles: true }));

    assertPaginationState(false, false, "2");
    assertTableData(allSamples, range(6, 10));

    getPageNum().value = "3";
    getPageNum().dispatchEvent(new Event("change", { bubbles: true }));

    assertPaginationState(false, true, "3");
    assertTableData(allSamples, [11]);

    getPageNum().value = "1";
    getPageNum().dispatchEvent(new Event("change", { bubbles: true }));

    assertPaginationState(true, false, "1");
    assertTableData(allSamples, range(1, 5));
  });

  it("filtering", async () => {
    const allSamples = [1, 2, 3, 4, 5, 6, 7, 10, 11, 21, 100, 199];
    setupStandardSamplesheetAttributes(allSamples);
    renderFilter();

    application = await startController();

    const clearButton = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="filterClearButton"]',
    );

    const filterButton = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="filterSearchButton"]',
    );

    const emptyState = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="emptyState"]',
    );

    assertPaginationOptions(["1", "2", "3"]);

    assertPaginationState(true, false, "1");
    expect(clearButton).toHaveClass("hidden");

    getNextBtn().click();
    getNextBtn().click();

    assertPaginationState(false, true, "3");

    await applyFilter("1");

    expect(clearButton).not.toHaveClass("hidden");

    assertPaginationOptions(["1", "2"], ["3"]);

    assertPaginationState(true, false, "1");

    assertTableData(allSamples, [1, 10, 11, 21, 100]);

    getNextBtn().click();

    assertPaginationState(false, true, "2");

    assertTableData(allSamples, [199]);

    await applyFilter("");

    assertPaginationOptions(["1", "2", "3"]);

    assertPaginationState(true, false, "1");
    expect(clearButton).toHaveClass("hidden");

    await applyFilter("2");

    expect(getPreviousBtn()).toBeNull();
    expect(getPageNum()).toBeNull();
    expect(getNextBtn()).toBeNull();

    expect(clearButton).not.toHaveClass("hidden");

    assertTableData(allSamples, [2, 21]);

    clearButton.click();

    vi.advanceTimersByTime(60);

    assertPaginationState(true, false, "1");

    assertPaginationOptions(["1", "2", "3"]);

    // test empty no samples found filter state with filter button click
    expect(emptyState).toHaveClass("hidden");
    document.querySelector("#samplesheet-filter").value = "invalid filter";
    filterButton.click();
    vi.advanceTimersByTime(60);

    expect(getPreviousBtn()).toBeNull();
    expect(getPageNum()).toBeNull();
    expect(getNextBtn()).toBeNull();
    expect(emptyState).not.toHaveClass("hidden");
  });

  it("can't submit without name", async () => {
    setupStandardSamplesheetAttributes(range(1, 5));
    application = await startController();
    const submitBtn = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="submit"]',
    );

    const errorMessageContainer = document.querySelector(
      "#workflow_execution_name_error",
    );

    const formFieldErrorMessage = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="formFieldErrorMessage"]',
    );

    expect(errorMessageContainer.textContent).not.toContain(
      "Name is required. Please enter a name for the workflow execution.",
    );

    expect(formFieldErrorMessage.textContent).not.toContain(
      "Please review the following problems:",
    );

    submitBtn.click();

    vi.advanceTimersByTime(60);
    expect(errorMessageContainer.textContent).toContain(
      "Name is required. Please enter a name for the workflow execution.",
    );
    expect(formFieldErrorMessage.textContent).toContain(
      "Please review the following problems:",
    );
  });

  it("empty file selection on required file field validation", async () => {
    // manually create sampleAttributes with empty file selection
    const samples = [1, 2];
    renderFullFixture();
    const sampleAttributesContainer =
      document.getElementById("sample_attributes");

    sessionStorage.setItem("selection-test-key", createSampleIds(samples));

    const fileAttributes = JSON.stringify(
      Object.fromEntries(
        samples.map((n) => [
          `sample-${n}-id`,
          {
            fastq_1: {
              filename: "No File Selected",
              attachment_id: "",
            },
            fastq_2: {
              filename: "No File Selected",
              attachment_id: "",
            },
          },
        ]),
      ),
    );

    const sampleAttributes = JSON.stringify(
      Object.fromEntries(
        samples.map((n) => [
          `sample-${n}-id`,
          {
            sample_id: `sample-${n}-id`,
            samplesheet_params: {
              sample: `SAMPLE-PUID-${n}`,
              fastq_1: "",
              fastq_2: "",
              metadata_1: "",
              sample_name: `SAMPLE NAME ${n}`,
            },
          },
        ]),
      ),
    );

    sampleAttributesContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
      class="hidden"
      data-nextflow--v2--samplesheet-target="sampleAttributes"
      data-allowed-to-update-samples="true"
      data-sample-attributes='${sampleAttributes}'
    ></div>
    <div
      class="hidden"
      data-nextflow--v2--samplesheet-target="fileAttributes"
    >
      ${fileAttributes}
    </div>`,
    );
    application = await startController();

    const submitBtn = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="submit"]',
    );

    const samplesheetErrorContainer = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="error"]',
    );

    const nameInput = document.querySelector("#workflow_execution_name");

    expect(samplesheetErrorContainer.textContent).not.toContain(
      "The following samples are missing required data",
    );

    nameInput.value = "test name";
    submitBtn.click();

    vi.advanceTimersByTime(60);

    expect(samplesheetErrorContainer.textContent).toContain(
      "The following samples are missing required data:",
    );
    expect(samplesheetErrorContainer.textContent).toContain(
      "- SAMPLE-PUID-1: fastq_1, fastq_2",
    );
    expect(samplesheetErrorContainer.textContent).toContain(
      "- SAMPLE-PUID-2: fastq_1, fastq_2",
    );
  });

  it("update samples is true", async () => {
    setupStandardSamplesheetAttributes([1]);

    const updateSamplesLabel = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="updateSamplesLabel"]',
    );
    const updateSamplesLabelParent = updateSamplesLabel.parentElement;
    const updateSamplesCheckbox = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="updateSamplesCheckbox"]',
    );

    expect(updateSamplesLabelParent).toHaveClass("hidden");
    application = await startController();

    expect(updateSamplesLabelParent).not.toHaveClass("hidden");
    expect(updateSamplesLabel.innerText).toContain(
      "Update samples with analysis results",
    );
    expect(updateSamplesCheckbox.disabled).toBe(false);
  });

  it("update samples is false", async () => {
    // manually create sampleAttributes with empty file selection
    const samples = [1, 2];
    renderFullFixture();
    const sampleAttributesContainer =
      document.getElementById("sample_attributes");

    sessionStorage.setItem("selection-test-key", createSampleIds(samples));

    const fileAttributes = JSON.stringify(
      Object.fromEntries(
        samples.map((n) => [
          `sample-${n}-id`,
          {
            fastq_1: {
              filename: "No File Selected",
              attachment_id: "",
            },
            fastq_2: {
              filename: "No File Selected",
              attachment_id: "",
            },
          },
        ]),
      ),
    );

    const sampleAttributes = JSON.stringify(
      Object.fromEntries(
        samples.map((n) => [
          `sample-${n}-id`,
          {
            sample_id: `sample-${n}-id`,
            samplesheet_params: {
              sample: `SAMPLE-PUID-${n}`,
              fastq_1: "",
              fastq_2: "",
              metadata_1: "",
              sample_name: `SAMPLE NAME ${n}`,
            },
          },
        ]),
      ),
    );

    sampleAttributesContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
      class="hidden"
      data-nextflow--v2--samplesheet-target="sampleAttributes"
      data-allowed-to-update-samples="false"
      data-sample-attributes='${sampleAttributes}'
    ></div>
    <div
      class="hidden"
      data-nextflow--v2--samplesheet-target="fileAttributes"
    >
      ${fileAttributes}
    </div>`,
    );

    const updateSamplesLabel = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="updateSamplesLabel"]',
    );
    const updateSamplesLabelParent = updateSamplesLabel.parentElement;
    const updateSamplesCheckbox = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="updateSamplesCheckbox"]',
    );

    expect(updateSamplesLabelParent).toHaveClass("hidden");
    application = await startController();

    expect(updateSamplesLabelParent).not.toHaveClass("hidden");
    expect(updateSamplesLabel.innerText).toContain(
      "You are not authorized to update samples with analysis results",
    );
    expect(updateSamplesCheckbox.disabled).toBe(true);
  });

  it("samplesheet updates file selection upon receiving payload, and retains the data during pagination", async () => {
    const allSamples = range(1, 11);
    setupStandardSamplesheetAttributes(allSamples);
    application = await startController();

    assertTableData(allSamples, range(1, 5));
    const samplesheetPayloadContainer = document.getElementById(
      "samplesheet-payload-container",
    );
    const filesPayload = JSON.stringify({
      files: [
        {
          filename: "new-fastq-1.fastq.gz",
          global_id: "new-fastq-1-global-id",
          id: "new-fastq-1-id",
          property: "fastq_1",
        },
        {
          filename: "new-fastq-2.fastq.gz",
          global_id: "new-fastq-2-global-id",
          id: "new-fastq-2-id",
          property: "fastq_2",
        },
      ],
      attachable_id: "sample-1-id",
    });
    const escapedFilesPayload = filesPayload.replaceAll('"', "&quot;");
    samplesheetPayloadContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
        hidden
        data-files="${escapedFilesPayload}"
        data-nextflow--v2--samplesheet-target="dataPayload"
        data-payload-type="files"
      ></div>`,
    );

    await Promise.resolve(); // await DOM to process and render changes

    // specifically grab sample-1's row so we're asserting the correct file cells
    let sample1Row = Array.from(document.querySelectorAll("tr")).find((row) =>
      row.textContent?.includes("SAMPLE-PUID-1"),
    );

    expect(sample1Row).toBeTruthy();

    expect(sample1Row.querySelector('[id$="_fastq_1"]')).toHaveTextContent(
      "new-fastq-1.fastq.gz",
    );

    expect(sample1Row.querySelector('[id$="_fastq_2"]')).toHaveTextContent(
      "new-fastq-2.fastq.gz",
    );

    getNextBtn().click();
    assertTableData(allSamples, range(6, 10));

    // file names don't appear on new page
    expect(
      document.querySelector('[data-test-selector="samplesheet-table"]'),
    ).not.toHaveTextContent("new-fastq-1.fastq.gz");

    expect(
      document.querySelector('[data-test-selector="samplesheet-table"]'),
    ).not.toHaveTextContent("new-fastq-2.fastq.gz");

    getPreviousBtn().click();

    // re-assert that sample-1 contains new file names
    sample1Row = Array.from(document.querySelectorAll("tr")).find((row) =>
      row.textContent?.includes("SAMPLE-PUID-1"),
    );

    expect(sample1Row).toBeTruthy();

    expect(sample1Row.querySelector('[id$="_fastq_1"]')).toHaveTextContent(
      "new-fastq-1.fastq.gz",
    );

    expect(sample1Row.querySelector('[id$="_fastq_2"]')).toHaveTextContent(
      "new-fastq-2.fastq.gz",
    );
  });

  it("samplesheet updates metadata upon receiving payload, and retains the data during pagination", async () => {
    const allSamples = range(1, 10);
    setupStandardSamplesheetAttributes(allSamples);
    application = await startController();

    assertTableData(allSamples, range(1, 5));
    const samplesheetPayloadContainer = document.getElementById(
      "samplesheet-payload-container",
    );
    const metadataPayload = {};

    for (let i = 2; i <= 10; i++) {
      const sampleId = `sample-${i}-id`;

      metadataPayload[sampleId] = {
        sample_id: sampleId,
        samplesheet_params: {
          metadata_1: `metadata-value-${i}`,
        },
      };
    }

    const escapedMetadataPayload = JSON.stringify(metadataPayload).replaceAll(
      '"',
      "&quot;",
    );
    samplesheetPayloadContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
        data-metadata='${escapedMetadataPayload}'
        data-headers='["metadata_1"]'
        data-nextflow--v2--samplesheet-target="dataPayload"
        data-payload-type="metadata"
      ></div>`,
    );

    await Promise.resolve();

    // also test manually inputting into metadata input
    const sample1MetadataInput = document.getElementById(
      "sample-1-id_metadata_1_input",
    );

    sample1MetadataInput.value = "manual value 1";

    sample1MetadataInput.dispatchEvent(
      new Event("change", {
        bubbles: true,
      }),
    );

    for (let i = 1; i <= 5; i++) {
      const sampleRow = Array.from(document.querySelectorAll("tr")).find(
        (row) => row.textContent?.includes(`SAMPLE-PUID-${i}`),
      );

      expect(sampleRow).toBeTruthy();
      // specific case for sample-1
      if (i === 1) {
        expect(
          sampleRow.querySelector('[id$="_metadata_1_input"]'),
        ).toHaveValue("manual value 1");
      } else {
        // get each specific row determined by PUID and verify the corresponding metadata value is correct
        expect(
          sampleRow.querySelector('[id$="_metadata_1"]'),
        ).toHaveTextContent(`metadata-value-${i}`);
      }
    }

    getNextBtn().click();

    for (let i = 6; i <= 10; i++) {
      // verify samples that were not on the samplesheet when metadata payload was parsed still have updated values
      const sampleRow = Array.from(document.querySelectorAll("tr")).find(
        (row) => row.textContent?.includes(`SAMPLE-PUID-${i}`),
      );

      expect(sampleRow).toBeTruthy();

      expect(sampleRow.querySelector('[id$="_metadata_1"]')).toHaveTextContent(
        `metadata-value-${i}`,
      );
    }
  });

  it("samplesheet select dropdown value change", async () => {
    const allSamples = range(1, 10);
    setupStandardSamplesheetAttributes(allSamples);
    application = await startController();

    assertTableData(allSamples, range(1, 5));

    // change a couple dropdown
    [1, 5].forEach((sampleNum) => {
      const dropdownCell = document.getElementById(
        `sample-${sampleNum}-id_fastmatch_category_dropdown`,
      );
      dropdownCell.value = sampleNum === 1 ? "query" : "reference";

      dropdownCell.dispatchEvent(
        new Event("change", {
          bubbles: true,
        }),
      );
    });

    // change page forward and back to verify if content is saved
    getNextBtn().click();
    getPreviousBtn().click();

    for (let i = 1; i <= 5; i++) {
      const dropdownCell = document.getElementById(
        `sample-${i}-id_fastmatch_category_dropdown`,
      );
      let expectedValue = "";
      if (i === 1) {
        expectedValue = "query";
      } else if (i === 5) {
        expectedValue = "reference";
      }

      expect(dropdownCell).toHaveValue(expectedValue);
    }
  });

  it("samplesheet select dropdown value change", async () => {
    const allSamples = range(1, 10);
    setupStandardSamplesheetAttributes(allSamples);
    application = await startController();

    assertTableData(allSamples, range(1, 5));

    // change a couple dropdown
    const inputCell = document.getElementById(
      `sample-1-id_an_input_cell_input`,
    );
    inputCell.value = "test input";

    inputCell.dispatchEvent(
      new Event("change", {
        bubbles: true,
      }),
    );

    // change page forward and back to verify if content is saved
    getNextBtn().click();
    getPreviousBtn().click();

    expect(inputCell).toHaveValue("test input");
  });

  it("formData of metadata submission upon metadata selection", async () => {
    const allSamples = range(1, 10);
    setupStandardSamplesheetAttributes(allSamples);
    renderMetadataParamsHeader();

    application = await startController();
    let submittedForm;

    const requestSubmit = vi
      .spyOn(HTMLFormElement.prototype, "requestSubmit")
      .mockImplementation(function () {
        submittedForm = this;
      });

    const metadataParamsHeader = document.getElementById(
      "workflow_execution_workflow_params_metadata_1_header",
    );
    const metadataSelect = document.querySelector("#field-metadata_1");

    expect(metadataParamsHeader).toHaveValue("metadata_1");
    metadataSelect.value = "age";
    metadataSelect.dispatchEvent(new Event("change", { bubbles: true }));

    expect(metadataParamsHeader).toHaveClass("ring-primary-500");
    expect(metadataParamsHeader).toHaveValue("age");
    expect(requestSubmit).toHaveBeenCalledOnce();
    expect(submittedForm).toBeInstanceOf(HTMLFormElement);

    const formData = new FormData(submittedForm);

    expect(formData.get("metadata_fields")).toBe('{"metadata_1":"age"}');

    expect(formData.get("sample_ids")).toBe(
      "sample-1-id,sample-2-id,sample-3-id,sample-4-id,sample-5-id,sample-6-id,sample-7-id,sample-8-id,sample-9-id,sample-10-id",
    );

    requestSubmit.mockRestore();

    vi.advanceTimersByTime(1010);
    expect(metadataParamsHeader).not.toHaveClass("ring-primary-500");
  });

  it("verify samplesheet submission form content with samplesheet changes", async () => {
    const allSamples = range(1, 2);
    setupStandardSamplesheetAttributes(allSamples);

    application = await startController();

    const nameInput = document.querySelector("#workflow_execution_name");
    nameInput.value = "a test name";

    // file change
    const samplesheetPayloadContainer = document.getElementById(
      "samplesheet-payload-container",
    );
    const filesPayload = JSON.stringify({
      files: [
        {
          filename: "new-fastq-1.fastq.gz",
          global_id: "new-fastq-1-global-id",
          id: "new-fastq-1-id",
          property: "fastq_1",
        },
        {
          filename: "new-fastq-2.fastq.gz",
          global_id: "new-fastq-2-global-id",
          id: "new-fastq-2-id",
          property: "fastq_2",
        },
      ],
      attachable_id: "sample-1-id",
    });
    const escapedFilesPayload = filesPayload.replaceAll('"', "&quot;");
    samplesheetPayloadContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
        hidden
        data-files="${escapedFilesPayload}"
        data-nextflow--v2--samplesheet-target="dataPayload"
        data-payload-type="files"
      ></div>`,
    );

    await Promise.resolve(); // await DOM to process and render changes

    // metadata change
    const metadataPayload = {};

    metadataPayload["sample-2-id"] = {
      sample_id: "sample-2-id",
      samplesheet_params: {
        metadata_1: "a_metadata_value",
      },
    };
    const escapedMetadataPayload = JSON.stringify(metadataPayload).replaceAll(
      '"',
      "&quot;",
    );
    samplesheetPayloadContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
        data-metadata='${escapedMetadataPayload}'
        data-headers='["metadata_1"]'
        data-nextflow--v2--samplesheet-target="dataPayload"
        data-payload-type="metadata"
      ></div>`,
    );

    await Promise.resolve(); // await DOM to process and render changes

    // dropdown change
    const dropdownCell = document.getElementById(
      "sample-1-id_fastmatch_category_dropdown",
    );
    dropdownCell.value = "query";
    dropdownCell.dispatchEvent(
      new Event("change", {
        bubbles: true,
      }),
    );

    let fetchOptions;

    vi.spyOn(HTMLFormElement.prototype, "requestSubmit").mockImplementation(
      function () {
        fetchOptions = {
          body: undefined,
          headers: {},
        };

        this.dispatchEvent(
          new CustomEvent("turbo:before-fetch-request", {
            bubbles: true,
            detail: {
              fetchOptions,
              resume: vi.fn(),
            },
          }),
        );
      },
    );

    const submitButton = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="submit"]',
    );

    submitButton.click();

    vi.advanceTimersByTime(60);

    expect(fetchOptions.headers["Content-Type"]).toBe("application/json");
    const body = JSON.parse(fetchOptions.body);
    expect(
      body.workflow_execution.samples_workflow_executions_attributes,
    ).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          sample_id: "sample-1-id",
          samplesheet_params: expect.objectContaining({
            sample: "SAMPLE-PUID-1",
            sample_name: "SAMPLE NAME 1",
            metadata_1: "",
            fastmatch_category: "query",
            fastq_1: "new-fastq-1-global-id",
            fastq_2: "new-fastq-2-global-id",
          }),
        }),
        expect.objectContaining({
          sample_id: "sample-2-id",
          samplesheet_params: expect.objectContaining({
            sample: "SAMPLE-PUID-2",
            sample_name: "SAMPLE NAME 2",
            metadata_1: "a_metadata_value",
            fastmatch_category: "",
            fastq_1: "gid://irida/Attachment/sample-2-fastq-1",
            fastq_2: "gid://irida/Attachment/sample-2-fastq-2",
          }),
        }),
      ]),
    );
    expect(body.workflow_execution.name).toEqual("a test name");
    expect(body.workflow_execution.namespace_id).toEqual("a_namespace_id");
  });

  it("unaligned selection ids and sample attributes id cause error", async () => {
    renderFullFixture();
    sessionStorage.setItem("selection-test-key", createSampleIds([1, 2]));
    const sampleAttributesContainer =
      document.getElementById("sample_attributes");
    sampleAttributesContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
      class="hidden"
      data-nextflow--v2--samplesheet-target="sampleAttributes"
      data-allowed-to-update-samples="true"
      data-sample-attributes='${createSampleAttributes([1])}'
    ></div>
    <div
      class="hidden"
      data-nextflow--v2--samplesheet-target="fileAttributes"
    >
      ${createFileAttributes([1])}
    </div>`,
    );
    application = await startController();

    const errorMessage = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="errorMessage"]',
    );

    expect(errorMessage).toHaveTextContent(
      "An error has occurred while processing your request. Please re-launch the workflow execution. If the issue persists, de-select and re-select the samples.",
    );
  });

  it("queued metadata changes", async () => {
    const allSamples = range(1, 10);
    sessionStorage.setItem("selection-test-key", createSampleIds(allSamples));

    renderBaseFixture();
    renderSamplesheetProperties();
    renderTable();
    renderTemplates();
    renderSelectionOutlet();
    renderMetadataParamsHeader();

    application = await startController();

    let submittedForm;
    let fetchOptions;

    const requestSubmit = vi
      .spyOn(HTMLFormElement.prototype, "requestSubmit")
      .mockImplementation(function () {
        submittedForm = this;

        fetchOptions = {
          body: undefined,
          headers: {},
        };

        this.dispatchEvent(
          new CustomEvent("turbo:before-fetch-request", {
            bubbles: true,
            detail: {
              fetchOptions,
              resume: vi.fn(),
            },
          }),
        );
      });

    const metadataParamsHeader = document.getElementById(
      "workflow_execution_workflow_params_metadata_1_header",
    );
    const metadataSelect = document.querySelector("#field-metadata_1");

    expect(metadataParamsHeader).toHaveValue("metadata_1");

    metadataSelect.value = "age";
    metadataSelect.dispatchEvent(new Event("change", { bubbles: true }));

    // The metadata change is queued because sample attributes aren't available yet.
    expect(requestSubmit).not.toHaveBeenCalled();

    const sampleAttributesContainer =
      document.getElementById("sample_attributes");

    sampleAttributesContainer.insertAdjacentHTML(
      "afterbegin",
      `<div
      class="hidden"
      data-nextflow--v2--samplesheet-target="sampleAttributes"
      data-allowed-to-update-samples="true"
      data-sample-attributes='${createSampleAttributes(allSamples)}'
    ></div>
    <div
      class="hidden"
      data-nextflow--v2--samplesheet-target="fileAttributes"
    >
      ${createFileAttributes(allSamples)}
    </div>`,
    );

    await Promise.resolve();

    expect(metadataParamsHeader).toHaveValue("age");

    // Submission now happens once the sample attributes are available.
    expect(requestSubmit).toHaveBeenCalledOnce();
    expect(submittedForm).toBeInstanceOf(HTMLFormElement);

    // Verify the Turbo request was configured correctly.
    expect(fetchOptions.headers).toEqual({
      "Content-Type": "application/json",
    });

    const body = JSON.parse(fetchOptions.body);

    expect(JSON.parse(body.metadata_fields)).toEqual({
      metadata_1: "age",
    });

    expect(body.sample_ids).toBe(
      "sample-1-id,sample-2-id,sample-3-id,sample-4-id,sample-5-id,sample-6-id,sample-7-id,sample-8-id,sample-9-id,sample-10-id",
    );

    requestSubmit.mockRestore();
  });

  it("no selection outlet results in processing error", async () => {
    renderBaseFixture();
    renderSamplesheetProperties();

    application = await startController();

    const errorMessage = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="errorMessage"]',
    );

    expect(errorMessage).toHaveTextContent(
      "An error has occurred while processing your request. Please re-launch the workflow execution. If the issue persists, de-select and re-select the samples.",
    );
  });

  it("renders the Turbo response when fetching sample attributes", async () => {
    globalThis.fetch = vi.fn();
    globalThis.Turbo = {
      renderStreamMessage: vi.fn(),
    };
    const allSamples = range(1, 2);
    setupStandardSamplesheetAttributes(allSamples);

    const html = `
    <turbo-stream action="update" target="sample_attributes">
      <template>
        <div>Sample attributes</div>
      </template>
    </turbo-stream>
  `;

    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValueOnce(
      new Response(html, {
        status: 200,
        headers: {
          "Content-Type": "text/vnd.turbo-stream.html",
        },
      }),
    );

    application = await startController();

    await vi.waitFor(() => {
      expect(fetchMock).toHaveBeenCalledOnce();

      expect(fetchMock.mock.calls[0][0]).toBe(
        "http://localhost:3000/-/workflow_executions/submissions/samplesheet",
      );

      expect(fetchMock.mock.calls[0][1]).toMatchObject({
        credentials: "same-origin",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "text/vnd.turbo-stream.html",
        },
      });

      const body = JSON.parse(fetchMock.mock.calls[0][1].body);

      expect(body).toMatchObject({
        authenticity_token: "an_authenticity_token",
        sample_ids: ["sample-1-id", "sample-2-id"],
      });

      expect(JSON.parse(body.properties)).toMatchObject({
        sample: {
          type: "string",
          meta: ["irida_id"],
          unique: true,
          required: true,
          cell_type: "sample_cell",
        },
        metadata_1: {
          type: "string",
          meta: ["metadata_1"],
          default: "",
          required: false,
          cell_type: "metadata_cell",
        },
        an_input_cell: {
          type: "string",
          default: "",
          required: false,
          cell_type: "input_cell",
        },
      });
    });
  });

  it("fetch sample attributes error state", async () => {
    const allSamples = range(1, 2);
    setupStandardSamplesheetAttributes(allSamples);

    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValueOnce({
      ok: false,
      status: 500,
      text: vi.fn(),
    });

    application = await startController();

    const renderStreamMessageMock = vi
      .spyOn(globalThis.Turbo, "renderStreamMessage")
      .mockImplementation(() => {});

    await vi.waitFor(() => {
      expect(fetchMock).toHaveBeenCalledOnce();
    });

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:3000/-/workflow_executions/submissions/samplesheet",
      expect.objectContaining({
        credentials: "same-origin",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "text/vnd.turbo-stream.html",
        },
      }),
    );

    expect(renderStreamMessageMock).not.toHaveBeenCalled();

    fetchMock.mockRestore();
    renderStreamMessageMock.mockRestore();
  });
});
