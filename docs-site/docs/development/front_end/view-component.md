---
id: view_component
sidebar_position: 2
---

# View Component

## Pathogen View Components

Prefer `Pathogen::*` components from the sibling [pathogen-view-components](https://github.com/phac-nml/pathogen-view-components) gem when building new reusable UI. Design rules live in that repository under `docs/lookbook/design_system/`.

For what belongs in the gem versus the host app, read Pathogen’s [Host and library boundary](https://github.com/phac-nml/pathogen-view-components/blob/main/docs/lookbook/design_system/06-host-library-boundary.md.erb) Lookbook page (local sibling: `../pathogen-view-components/docs/lookbook/design_system/06-host-library-boundary.md.erb`).

End-state for IRIDA Next: reusable UI is Pathogen-only. Existing `Viral::*` components are legacy debt — replace call sites with `Pathogen::*` (or promote the pattern into Pathogen), then delete the Viral class. Do not add new Viral components.

To develop against a local sibling checkout of the gem, see [Useful Commands](../useful_commands.md#local-pathogen-view-components-sibling-checkout) (`USE_LOCAL_PATHOGEN=1`). Open `irida-next-pathogen.code-workspace` in a code editor (VS Code, Cursor, etc.) for a multi-root workspace that includes both repositories.

## Browse components with Lookbook

Use [Lookbook](https://v2.lookbook.build/guide) at `http://localhost:3000/rails/lookbook` (development only) to browse and interact with ViewComponent previews.

## Best practices

- When creating a new HTML view, use existing components instead of plain HTML tags with Tailwind CSS classes.
- When updating an existing HTML view—for example, an SVG icon still written as plain HTML—consider migrating it to a ViewComponent.
- When creating a new component, also add [previews](https://viewcomponent.org/guide/previews.html). Previews make the component discoverable in Lookbook and easier to test across states.
