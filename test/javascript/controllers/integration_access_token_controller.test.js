import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import IntegrationAccessTokenController from "../../../app/javascript/controllers/integration_access_token_controller.js";

const IDENTIFIER = "integration-access-token";
const TOKEN = "secret-token";
const TARGET = "https://example.com";

describe("IntegrationAccessTokenController", () => {
  let application;

  afterEach(async () => {
    vi.useRealTimers();
    await stopApplication(application);
  });

  async function mount() {
    document.body.innerHTML = `
      <div data-controller="${IDENTIFIER}"
           data-${IDENTIFIER}-token-value="${TOKEN}"
           data-${IDENTIFIER}-target-value="${TARGET}"></div>`;
    vi.useFakeTimers();
    application = startApplication();
    application.register(IDENTIFIER, IntegrationAccessTokenController);
    await Promise.resolve();
  }

  it("posts the token to an available opener and closes the window", async () => {
    const postMessage = vi.fn();
    const close = vi.fn();
    vi.stubGlobal("opener", { closed: false, postMessage });
    vi.stubGlobal("close", close);

    await mount();
    vi.advanceTimersByTime(3000);

    expect(postMessage).toHaveBeenCalledWith(TOKEN, TARGET);
    expect(close).toHaveBeenCalledOnce();
  });

  it("logs an error when the opener is unavailable", async () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const close = vi.fn();
    vi.stubGlobal("opener", null);
    vi.stubGlobal("close", close);

    await mount();
    vi.advanceTimersByTime(3000);

    expect(errorSpy).toHaveBeenCalledWith("Parent window unavailable");
    expect(close).toHaveBeenCalledOnce();
  });

  it("logs an error when posting the token throws", async () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const failure = new Error("boom");
    vi.stubGlobal("opener", {
      closed: false,
      postMessage: () => {
        throw failure;
      },
    });
    vi.stubGlobal("close", vi.fn());

    await mount();
    vi.advanceTimersByTime(3000);

    expect(errorSpy).toHaveBeenCalledWith("Failed to send token:", failure);
  });
});
