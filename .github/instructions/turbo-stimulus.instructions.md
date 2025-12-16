---
applyTo: "**/*.js,**/*.erb,**/*.html.erb"
---
# Turbo and Stimulus Guidelines

## Turbo Core Concepts
- Turbo Drive for full-page navigation without page reloads
- Turbo Frames for independent segments on a page
- Turbo Streams for live page updates over WebSocket/SSE
- Always build with progressive enhancement in mind

## Turbo Drive
- Accelerates navigation by avoiding full page reloads
- Intercepts link clicks and form submissions within the same domain
- Persists JavaScript window and document objects between navigations
- Use `data-turbo="false"` to opt out for specific links or forms
- Use `data-turbo-action="replace"` for navigation without pushing history
- Monitor navigation with `turbo:before-visit`, `turbo:visit`, and `turbo:load` events
- Annotate asset links with `data-turbo-track="reload"` to force reload when they change

## Turbo Frames
- Use frames to decompose pages into independent contexts with `<turbo-frame id="unique_id">`
- Scope navigation to within a frame (links and forms inside a frame will only update that frame)
- Lazy-load frames with `src` attribute pointing to a URL
- Use `target="_top"` on links inside frames to break out of the frame context
- Target other frames with `data-turbo-frame="target_frame_id"` on links/forms
- Use `loading="lazy"` for frames that are not initially visible (modals, hidden sections)
- Consider cache benefits when breaking pages into frames (different expiration times)
- Use `turbo:before-frame-render` for custom frame rendering or animations

## Turbo Streams
- Update specific parts of a page with `<turbo-stream>` elements
- Use actions: append, prepend, replace, update, remove, before, after, morph, refresh
- Target elements by ID with the `target` attribute or by query with `targets`
- Deliver streams in response to form submissions with MIME type `text/vnd.turbo-stream.html`
- Broadcast Streams over WebSocket or SSE for real-time updates
- Design Stream templates to be reusable across different delivery methods
- Follow the pattern of wrapping HTML content in a `<template>` tag:
```html
<turbo-stream action="append" target="messages">
  <template>
    <div id="message_1">New content</div>
  </template>
</turbo-stream>
```

## Smooth Page Refreshes
- Use morphing for smoother page refreshes by adding `<meta name="turbo-refresh-method" content="morph">`
- Preserve scroll position with `<meta name="turbo-refresh-scroll" content="preserve">`
- Exclude sections from morphing with `data-turbo-permanent`
- Use `refresh="morph"` for turbo frames that should be morphed on refresh

## Turbo Prefetching and Preloading
- Enable prefetching with `<meta name="turbo-prefetch" content="true">` (default in Turbo v8)
- Disable prefetching on specific links with `data-turbo-prefetch="false"`
- Preload important links with `data-turbo-preload` to make transitions instant

## Stimulus Controllers
- Name controllers semantically based on their behavior
- Keep controllers focused on a single responsibility
- Use data attributes for configuration values
- Leverage Stimulus lifecycle methods appropriately (connect, disconnect)
- Use values API for dynamic properties that can change
- Document controllers with clear comments describing their purpose
- Import controllers properly using Import Maps
- You do not need to import each Stimulus controller individually in the `index.js` file.

## Stimulus Actions
- Use meaningful action names based on the behavior (e.g., `submit`, `toggle`)
- Prefer using HTML data attributes over direct event binding
- Follow the format `data-action="controller#method"` consistently
- Handle events appropriately with preventDefault() when needed
- Keep action methods small and focused

## Stimulus Targets
- Define targets for elements that will be manipulated
- Ensure the controller has clearly defined targets
- Action methods are focused on single responsibilities
- The HTML uses the proper data attributes for actions and targets
- Event handling is done declaratively through data attributes
- Give targets descriptive names based on their purpose
- Use proper Stimulus target accessors to leverage Stimulus's built-in functionality rather than falling back to manual DOM querying
- Use target accessors in controller methods (`this.targetElement`)
- Check for target existence before manipulating (`this.hasTargetElement`)
- Use target collection when working with multiple similar elements

## Integration with Turbo
- Use Stimulus for behavior, Turbo for navigation and updates
- Respond to Turbo lifecycle events in Stimulus controllers
- Avoid duplicating event handlers by using Stimulus' disconnect lifecycle
- Design controllers that can handle being connected/disconnected during Turbo navigation
- Use Stimulus to enhance Turbo Stream responses with additional behavior
