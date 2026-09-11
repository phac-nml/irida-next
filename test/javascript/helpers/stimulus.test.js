import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "./stimulus.js";

describe("Stimulus test lifecycle", () => {
  let application;
  afterEach(async () => {
    await stopApplication(application);
  });

  it("disconnects controllers and releases document listeners before stopping", async () => {
    const disconnected = vi.fn();
    const listener = vi.fn();
    class Probe extends Controller {
      connect() {
        document.addEventListener("probe", listener);
      }
      disconnect() {
        document.removeEventListener("probe", listener);
        disconnected();
      }
    }
    document.body.innerHTML = '<div data-controller="probe"></div>';
    application = startApplication();
    application.register("probe", Probe);
    await Promise.resolve();
    document.dispatchEvent(new Event("probe"));
    expect(listener).toHaveBeenCalledOnce();
    await stopApplication(application);
    application = undefined;
    expect(disconnected).toHaveBeenCalledOnce();
    document.dispatchEvent(new Event("probe"));
    expect(listener).toHaveBeenCalledOnce();
  });

  it("reports an action error instead of silently logging it", async () => {
    class BrokenAction extends Controller {
      run() {
        throw new Error("Broken action");
      }
    }
    document.body.innerHTML =
      '<button data-controller="broken" data-action="broken#run">Run</button>';
    application = startApplication();
    application.register("broken", BrokenAction);
    await Promise.resolve();
    document.querySelector("button").click();
    const stopping = stopApplication(application);
    application = undefined;
    await expect(stopping).rejects.toThrow();
  });

  it.each(["connect", "disconnect"])(
    "fails the test when Stimulus catches a %s error",
    async (callback) => {
      const failure = new Error("Broken lifecycle");
      class Broken extends Controller {
        [callback]() {
          throw failure;
        }
      }
      document.body.innerHTML = '<div data-controller="broken"></div>';
      application = startApplication();
      application.register("broken", Broken);
      await Promise.resolve();
      const stopping = stopApplication(application);
      application = undefined;
      await expect(stopping).rejects.toThrow();
    },
  );
});
