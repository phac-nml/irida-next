import { Application } from "@hotwired/stimulus";
import { expect } from "vitest";

const errors = new WeakMap();

export function startApplication() {
  const application = Application.start();
  const captured = [];
  errors.set(application, captured);
  application.handleError = (error) => captured.push(error);
  return application;
}

export async function stopApplication(application) {
  if (!application) return;
  // Stimulus must observe removal before its observers are stopped.
  document.body.replaceChildren();
  await Promise.resolve();
  await Promise.resolve();
  application.stop();
  expect(errors.get(application)).toEqual([]);
}
