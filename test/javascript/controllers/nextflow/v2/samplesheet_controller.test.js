import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import SamplesheetController from "../../../../../app/javascript/controllers/nextflow/v2/samplesheet_controller.js";
import SelectionController from "../../../../../app/javascript/controllers/selection_controller.js";

const setupSamplesheetAttributes = (samples) => {
  renderFixture();

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

  const rows = [...tableBody.querySelectorAll("tr")].map((row) =>
    [...row.querySelectorAll("th, td")].map((cell) => cell.textContent.trim()),
  );

  const expectedRows = expectedSamples.map((n) => [
    `SAMPLE-PUID-${n}`,
    `sample_${n}_fastq_1.fastq.gz`,
    `sample_${n}_fastq_2.fastq.gz`,
  ]);

  expect(rows).toEqual(expectedRows);

  const displayedValues = rows.flat();

  allSamples
    .filter((n) => !expectedSamples.includes(n))
    .forEach((n) => {
      expect(displayedValues).not.toContain(`SAMPLE-PUID-${n}`);
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

  await new Promise((resolve) => setTimeout(resolve, 60));
};

/* eslint-disable no-useless-escape */
function renderFixture() {
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
    <input type="hidden" name="authenticity_token" value="I75TYYF0Z5cwjbODirsbI0HMR-6Ei8WFl97ZFJHYVGGQTb2Dqfw93BCG7A4sTbqzs6jxL2kSewIM9aakdw-SLQ">
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

    <input value="b3d29210-cefc-4b22-ad8e-c44c332b6c40" type="hidden" name="workflow_execution[namespace_id]" id="workflow_execution_namespace_id">

    <input value="phac-nml/iridanextexample" type="hidden" name="workflow_execution[metadata][pipeline_id]" id="workflow_execution_metadata_pipeline_id">
    <input value="1.0.3" type="hidden" name="workflow_execution[metadata][workflow_version]" id="workflow_execution_metadata_workflow_version">

    <h2>Input/output options</h2>
    <p>Define where the pipeline should find input data and save output data.</p>

    <div>
      <div id="samplesheet_message" data-nextflow--v2--samplesheet-target="samplesheetMessagesContainer"></div>

      <div id="samplesheet">
  <div
    class="hidden"
    data-nextflow--v2--samplesheet-target="samplesheetProperties"
    data-properties="{&quot;sample&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;pattern&quot;:&quot;^\\\\S+$&quot;,&quot;meta&quot;:[&quot;id&quot;],&quot;unique&quot;:true,&quot;errorMessage&quot;:&quot;Sample name must be provided and cannot contain spaces&quot;,&quot;required&quot;:true,&quot;cell_type&quot;:&quot;sample_cell&quot;},&quot;fastq_1&quot;:{&quot;type&quot;:&quot;string&quot;,&quot;pattern&quot;:&quot;^\\\\S+\\\\.f(ast)?q(\\\\.gz)?$&quot;,&quot;errorMessage&quot;:&quot;FastQ file for reads 1 must be provided, cannot contain spaces and must have the extension: '.fq', '.fastq', '.fq.gz' or '.fastq.gz'&quot;,&quot;required&quot;:true,&quot;cell_type&quot;:&quot;fastq_cell&quot;,&quot;autopopulate&quot;:true},&quot;fastq_2&quot;:{&quot;errorMessage&quot;:&quot;FastQ file for reads 2 cannot contain spaces and must have the extension: '.fq', '.fastq', '.fq.gz' or '.fastq.gz'&quot;,&quot;anyOf&quot;:[{&quot;type&quot;:&quot;string&quot;,&quot;pattern&quot;:&quot;^\\\\S+\\\\.f(ast)?q(\\\\.gz)?$&quot;},{&quot;type&quot;:&quot;string&quot;,&quot;maxLength&quot;:0}],&quot;required&quot;:false,&quot;cell_type&quot;:&quot;fastq_cell&quot;,&quot;pattern&quot;:&quot;^\\\\S+\\\\.f(ast)?q(\\\\.gz)?$&quot;,&quot;autopopulate&quot;:true}}"
  ></div>
        <turbo-frame id="sample_attributes">
        </turbo-frame>

        <div>
          <label>
            Samples (5)
          </label>

          <div>
            <label for="samplesheet-filter">
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
            </button>
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
          <div>
            <table data-test-selector="samplesheet-table" data-controller="table" data-action="focusin-&gt;table#handleCellFocus">
              <thead>
                <tr>
                  <th>
                    <div>
                      sample
                      <span>(Required)</span>
                    </div>
                  </th>

                  <th>
                    <div>
                      fastq_1
                      <span>(Required)</span>
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
            </table>
          </div>
        </div>

        <div data-nextflow--v2--samplesheet-target="emptyState">
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

      <template data-nextflow--v2--samplesheet-target="trTemplate">
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
          <input value="b3d29210-cefc-4b22-ad8e-c44c332b6c40" type="hidden" name="namespace_id" id="namespace_id">
        </form>
      </template>
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
      <input type="hidden" name="authenticity_token" value="f8UGC6O6puKbpX_slk0n2j28NoMuktoMEr9wzm8witWOWrjDgMKV2xfEO05eb1XWC__rdSyP5wBcdJUvp8jG9A">
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
<div
    hidden
    id="samples-table"
    data-controller="selection"
    data-selection-storage-key-value="selection-test-key"
      data-selection-max-selection-value="1000"
      data-selection-limit-message-value="test limit message"
      data-selection-storage-limit-message-value="test storaget lmimit message"
  ></div>
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
  });

  afterEach(() => {
    application?.stop();
    vi.useRealTimers();
  });

  it("no pagination with 5 samples", async () => {
    setupSamplesheetAttributes(range(1, 5));
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
    setupSamplesheetAttributes(allSamples);
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
    setupSamplesheetAttributes(allSamples);
    application = await startController();

    const clearButton = document.querySelector(
      '[data-nextflow--v2--samplesheet-target="filterClearButton"]',
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

    await new Promise((resolve) => setTimeout(resolve, 60));

    assertPaginationState(true, false, "1");

    assertPaginationOptions(["1", "2", "3"]);
  });

  it("can't submit without name", async () => {
    setupSamplesheetAttributes(range(1, 5));
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

    await new Promise((resolve) => setTimeout(resolve, 60));
    expect(errorMessageContainer.textContent).toContain(
      "Name is required. Please enter a name for the workflow execution.",
    );
    expect(formFieldErrorMessage.textContent).toContain(
      "Please review the following problems:",
    );
  });
});
