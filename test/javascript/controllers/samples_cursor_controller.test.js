import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import SamplesCursorController from "../../../app/javascript/controllers/samples_cursor_controller.js";

describe("samples cursor", () => {
  let application;
  let frames;

  async function start() {
    frames = [];
    vi.stubGlobal("requestAnimationFrame", (callback) => {
      frames.push(callback);
      return frames.length;
    });
    vi.stubGlobal("cancelAnimationFrame", vi.fn());
    document.body.innerHTML = `<div id="sort-status" role="status"></div><turbo-frame id="results" data-controller="samples-cursor" data-samples-cursor-status-id-value="sort-status"
      data-action="turbo:before-fetch-request->samples-cursor#request turbo:before-frame-render->samples-cursor#renderFrame turbo:before-stream-render@document->samples-cursor#renderStream turbo:frame-load->samples-cursor#restore">
      <div data-pathogen--data-grid-target="scrollContainer"></div>
      <span data-cursor-refresh-url="/samples?q%5Bsort%5D=metadata_collection+date+asc" data-cursor-sort-message="Sorted by Collection date, ascending."></span>
      <button data-sort-field="metadata_collection date" data-sort-url="/samples?q%5Bsort%5D=metadata_collection+date+asc"
        data-action="click->samples-cursor#sort">Collection date</button>
    </turbo-frame>`;
    application = startApplication();
    application.register("samples-cursor", SamplesCursorController);
    await Promise.resolve();
    return document.querySelector("turbo-frame");
  }

  function request(target, url = "/samples") {
    const fetchOptions = { headers: {}, signal: new AbortController().signal };
    target.dispatchEvent(
      new CustomEvent("turbo:before-fetch-request", {
        bubbles: true,
        detail: { url: new URL(url, document.baseURI), fetchOptions },
      }),
    );
    return {
      id: fetchOptions.headers["X-Samples-Cursor-Request"],
      signal: fetchOptions.signal,
    };
  }

  function frameRender(frame, id) {
    const newFrame = document.createElement("turbo-frame");
    newFrame.dataset.cursorRequestId = id;
    const render = vi.fn();
    const detail = { newFrame, render };
    frame.dispatchEvent(
      new CustomEvent("turbo:before-frame-render", { detail }),
    );
    return { render, apply: () => detail.render(frame, newFrame) };
  }

  function streamRender(id, target = "results") {
    const stream = document.createElement("turbo-stream");
    stream.dataset.cursorRequestId = id;
    stream.setAttribute("target", target);
    document.body.appendChild(stream);
    const render = vi.fn();
    const detail = { render };
    stream.dispatchEvent(
      new CustomEvent("turbo:before-stream-render", { bubbles: true, detail }),
    );
    return { render, apply: () => detail.render(stream) };
  }

  function acceptSort(frame) {
    const { id } = request(frame, frame.src);
    frameRender(frame, id).apply();
    frame.dispatchEvent(new Event("turbo:frame-load"));
  }

  afterEach(async () => {
    await stopApplication(application);
  });

  it("resets the frame query and restores the same sort control after horizontal rendering", async () => {
    const frame = await start();
    frame.querySelector("div").scrollLeft = 420;
    frame.querySelector("button").click();
    expect(frame.src).toContain("q%5Bsort%5D=metadata_collection+date+asc");
    const replacement = frame.querySelector("button").cloneNode(true);
    frame.querySelector("button").remove();
    frame.querySelector("div").scrollLeft = 0;
    frame.querySelector("div").addEventListener("scroll", () => {
      frame.appendChild(replacement);
    });
    acceptSort(frame);
    frames.shift()();
    frames.shift()();
    expect(frame.querySelector("div").scrollLeft).toBe(420);
    expect(document.activeElement).toBe(replacement);
  });

  it("does not steal focus after ordinary frame loads", async () => {
    const frame = await start();
    frame.dispatchEvent(new Event("turbo:frame-load"));
    expect(frames).toHaveLength(0);
  });

  it("does not move focus back after the user leaves the result frame", async () => {
    const frame = await start();
    frame.querySelector("button").click();
    const outside = document.createElement("button");
    document.body.appendChild(outside);
    outside.focus();
    acceptSort(frame);
    expect(frames).toHaveLength(0);
    expect(document.activeElement).toBe(outside);
  });

  it("does not steal focus if the user leaves while virtual columns are rendering", async () => {
    const frame = await start();
    frame.querySelector("button").click();
    acceptSort(frame);
    frames.shift()();
    const outside = document.createElement("button");
    document.body.appendChild(outside);
    outside.focus();
    frames.shift()();
    expect(document.activeElement).toBe(outside);
  });

  it("cancels pending focus restoration when disconnected", async () => {
    const frame = await start();
    frame.querySelector("button").click();
    acceptSort(frame);
    frame.remove();
    await Promise.resolve();
    expect(cancelAnimationFrame).toHaveBeenCalled();
  });
  it("announces only the accepted sort in the persistent polite status", async () => {
    const frame = await start();
    frame.querySelector("button").click();
    const first = request(frame, frame.src);
    const stale = frameRender(frame, first.id);
    const second = request(frame, frame.src);
    stale.apply();
    frame.dispatchEvent(new Event("turbo:frame-load"));
    expect(document.getElementById("sort-status").textContent).toBe("");
    frameRender(frame, second.id).apply();
    frame.dispatchEvent(new Event("turbo:frame-load"));
    expect(document.getElementById("sort-status").textContent).toBe(
      "Sorted by Collection date, ascending.",
    );
  });

  it("cancels an older sort and rejects its render after a newer filter response", async () => {
    const frame = await start();
    frame.querySelector("button").click();
    const first = request(frame, frame.src);
    const stale = frameRender(frame, first.id);
    const form = document.createElement("form");
    frame.appendChild(form);
    const second = request(form, "/samples/search");
    const latest = streamRender(second.id);
    latest.apply();
    stale.apply();
    frame.dispatchEvent(new Event("turbo:frame-load"));
    expect(first.signal.aborted).toBe(true);
    expect(latest.render).toHaveBeenCalledOnce();
    expect(stale.render).not.toHaveBeenCalled();
    expect(document.getElementById("sort-status").textContent).toBe("");
    expect(frames).toHaveLength(0);
  });

  it("cancels nested metadata submissions and rejects late streams when a newer sort starts", async () => {
    const frame = await start();
    const nested = document.createElement("turbo-frame");
    nested.innerHTML = "<form></form>";
    frame.appendChild(nested);
    const metadata = request(nested.querySelector("form"), "/samples/search");
    const stale = streamRender(metadata.id);
    frame.querySelector("button").click();
    acceptSort(frame);
    stale.apply();
    expect(metadata.signal.aborted).toBe(true);
    expect(stale.render).not.toHaveBeenCalled();
  });

  it("does not cancel query requests when the nested metadata list loads", async () => {
    const frame = await start();
    const current = request(frame);
    const nested = document.createElement("turbo-frame");
    frame.appendChild(nested);
    const list = request(nested, "/metadata_templates/list");
    expect(list.id).toBeUndefined();
    expect(current.signal.aborted).toBe(false);
    frame.remove();
    await Promise.resolve();
    expect(current.signal.aborted).toBe(true);
  });

  it("respects cancellation by Turbo and leaves unrelated streams alone", async () => {
    const frame = await start();
    const controller = new AbortController();
    const fetchOptions = { headers: {}, signal: controller.signal };
    frame.dispatchEvent(
      new CustomEvent("turbo:before-fetch-request", {
        detail: { url: new URL("/samples", document.baseURI), fetchOptions },
      }),
    );
    controller.abort();
    expect(fetchOptions.signal.aborted).toBe(true);
    const other = streamRender("unrelated", "another-frame");
    other.apply();
    expect(other.render).toHaveBeenCalledOnce();
  });
});
