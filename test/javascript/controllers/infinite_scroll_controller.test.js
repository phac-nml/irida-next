import { afterEach, describe, expect, it, vi } from "vitest";
import { Controller } from "@hotwired/stimulus";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import InfiniteScrollController from "../../../app/javascript/controllers/infinite_scroll_controller.js";

let storedItems = [];

// Minimal stand-in for the selection outlet; only the id source is exercised.
class SelectionOutletStub extends Controller {
  getOrCreateStoredItems() {
    return storedItems;
  }
}

function renderFixture({
  items = [],
  separatePe = false,
  includeSelectionCount = true,
} = {}) {
  storedItems = items;
  const selectionCount = includeSelectionCount
    ? '<span data-infinite-scroll-target="selectionCount"></span>'
    : "";

  return `
    <div id="selection-root" data-controller="selection"></div>
    <div
      id="scroll-root"
      data-controller="infinite-scroll"
      data-infinite-scroll-selection-outlet="#selection-root"
      data-infinite-scroll-paged-field-name-value="sample_ids[]"
      data-infinite-scroll-singular-description-value="1 sample selected"
      data-infinite-scroll-plural-description-value="COUNT_PLACEHOLDER samples selected"
      data-infinite-scroll-non-zero-header-value="COUNT_PLACEHOLDER selected"
      data-infinite-scroll-separate-pe-attachments-value="${separatePe}"
    >
      ${selectionCount}
      <span data-infinite-scroll-target="summary"></span>
      <div data-infinite-scroll-target="scrollable">
        <form data-infinite-scroll-target="pageForm">
          <div data-infinite-scroll-target="pageFormContent"></div>
        </form>
      </div>
    </div>
  `;
}

const root = () => document.getElementById("scroll-root");
const summary = () =>
  document.querySelector('[data-infinite-scroll-target="summary"]');
const selectionCount = () =>
  document.querySelector('[data-infinite-scroll-target="selectionCount"]');
const scrollable = () =>
  document.querySelector('[data-infinite-scroll-target="scrollable"]');
const pageContent = () =>
  document.querySelector('[data-infinite-scroll-target="pageFormContent"]');
const pagedInputs = () =>
  Array.from(pageContent().querySelectorAll('input[name="sample_ids[]"]'));
const pageValue = () => pageContent().querySelector('input[name="page"]').value;

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    root(),
    "infinite-scroll",
  );
}

async function mount(options) {
  document.body.innerHTML = renderFixture(options);
  const submitSpy = vi
    .spyOn(HTMLFormElement.prototype, "requestSubmit")
    .mockImplementation(() => {});
  const application = startApplication();
  application.register("selection", SelectionOutletStub);
  application.register("infinite-scroll", InfiniteScrollController);
  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));
  return { application, submitSpy };
}

describe("infinite scroll controller", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
    document.body.innerHTML = "";
  });

  it("marks connected, renders the plural summary and header, and submits the first page", async () => {
    let submitSpy;
    ({ application, submitSpy } = await mount({ items: ["1", "2", "3"] }));

    expect(root().getAttribute("data-connected")).toBe("true");
    expect(summary().innerHTML).toBe("3 samples selected");
    expect(selectionCount().innerHTML).toBe("3 selected");
    expect(pagedInputs().map((input) => input.value)).toEqual(["1", "2", "3"]);
    expect(pageValue()).toBe("1");
    expect(submitSpy).toHaveBeenCalledTimes(1);
  });

  it("renders the singular summary and skips the header when there is no count target", async () => {
    ({ application } = await mount({
      items: ["1"],
      includeSelectionCount: false,
    }));

    expect(summary().innerHTML).toBe("1 sample selected");
    expect(selectionCount()).toBeNull();
  });

  it("loads additional pages on scroll until the ids are exhausted", async () => {
    const items = Array.from({ length: 250 }, (_, index) => String(index + 1));
    let submitSpy;
    ({ application, submitSpy } = await mount({ items }));
    const controller = controllerFor(application);

    expect(submitSpy).toHaveBeenCalledTimes(1);
    expect(pageValue()).toBe("1");
    expect(pagedInputs()).toHaveLength(100);

    controller.scroll();
    expect(submitSpy).toHaveBeenCalledTimes(2);
    expect(pageValue()).toBe("2");
    expect(pagedInputs()).toHaveLength(100);

    controller.scroll();
    expect(submitSpy).toHaveBeenCalledTimes(3);
    expect(pageValue()).toBe("3");
    expect(pagedInputs()).toHaveLength(50);

    // All ids are consumed, so a further scroll submits nothing.
    controller.scroll();
    expect(submitSpy).toHaveBeenCalledTimes(3);
  });

  it("does not load more when the user has not scrolled to the bottom", async () => {
    const items = Array.from({ length: 150 }, (_, index) => String(index + 1));
    let submitSpy;
    ({ application, submitSpy } = await mount({ items }));
    expect(submitSpy).toHaveBeenCalledTimes(1);

    const element = scrollable();
    Object.defineProperty(element, "scrollHeight", {
      value: 1000,
      configurable: true,
    });
    Object.defineProperty(element, "clientHeight", {
      value: 200,
      configurable: true,
    });
    Object.defineProperty(element, "scrollTop", {
      value: 0,
      configurable: true,
    });

    controllerFor(application).scroll();
    expect(submitSpy).toHaveBeenCalledTimes(1);
  });

  it("flattens paired-end attachment ids when separatePeAttachments is enabled", async () => {
    ({ application } = await mount({
      items: ['["a","b"]', "5", "not-json"],
      separatePe: true,
    }));

    expect(pagedInputs().map((input) => input.value)).toEqual([
      "a",
      "b",
      "5",
      "not-json",
    ]);
    expect(summary().innerHTML).toBe("4 samples selected");
  });
});
