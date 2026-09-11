# JavaScript and Stimulus tests

Run `pnpm run test:js` for fast feedback. Run `pnpm run test:js:coverage`
before opening a PR; CI runs this command and enforces the existing per-file
coverage thresholds. Vitest shuffles test order by default, using a new seed for
each run. To reproduce a failure, use the seed printed in the test output:
`pnpm run test:js:coverage --sequence.seed=<reported-seed>`.
Test discovery must find at least one test.

## Controller fixtures and lifecycle

Mirror implementation paths under `test/javascript`. Use a real Stimulus
application and representative DOM markup, including actions, targets and outlets.
Import `startApplication` and `stopApplication` from `test/javascript/helpers/stimulus.js`.
Register controllers after starting the application, then await connection before
interacting. For asynchronous rendering, wait for an observable state rather than
sleeping for an arbitrary interval.

Always await `stopApplication(application)` in an async `afterEach` callback,
before restoring mocks or returning to real timers. The helper removes fixtures,
lets Stimulus disconnect controllers, and only then stops its observers. It also
fails the test if Stimulus caught an unexpected lifecycle or action error.
Calling `application.stop()` alone does not disconnect controllers.

For lifecycle regressions, remove and reinsert the fixture while the application
is running. Assert observable cleanup: document events no longer act on removed
controllers, pending timers cannot update detached UI, and reconnecting does not
duplicate listeners. Do not substitute a direct `disconnect()` call for these tests.

## Assertions and mocks

Prefer `@testing-library/user-event` for ordinary clicks, typing and keyboard
interaction. Use explicit DOM events for Turbo events and precise event details.
Assert visible state, submitted values, focus, ARIA attributes and external effects.
Direct method calls are appropriate for deliberate controller APIs and pure utilities.
Avoid assertions that merely repeat an implementation or count internal calls.

Use `vi.spyOn` for existing methods, and `vi.stubGlobal` for globals such as `Turbo`.
Global stubs are restored after each test. Do not assign mocks directly to browser
objects or prototypes. The shared `scrollIntoView` shim supplies a method to spy on;
it does not simulate scrolling. The default `matchMedia` shim is static; tests of
media-query changes must supply an event-capable mock.

Keep mocks local and minimal. Mock external boundaries, not the controller being
tested. Every test must create the state it needs, including storage and mock
implementations. Pair fake timers with explicit advancement and restore real timers
after lifecycle cleanup. Test rejected promises and disconnects during pending work.

## Coverage and browser checks

Add a per-file threshold only after meaningful tests reach 100% statements,
branches, functions and lines. Review every coverage exclusion; do not hide a
reachable branch to satisfy a percentage. Coverage is evidence of execution, not
proof that assertions detect regressions.

Keep focused Rails/browser tests for real rendering, positioning, native dialogs,
scrolling and end-to-end Turbo behavior. jsdom does not perform layout. Maintain
small, independently reviewable PRs by subsystem. Refactor production code only
when a demonstrated defect or a concrete testing boundary justifies the change;
do not expose private methods solely to test them.
