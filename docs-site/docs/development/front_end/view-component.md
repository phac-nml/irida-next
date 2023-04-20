---
id: view_component
sidebar_position: 2
---

# View Component

## Browse components with LookBook

We have a [LookBook](https://v2.lookbook.build/guide) at `http://localhost:3000/rails/lookbook` (only available in development mode) to browse and interact with ViewComponent previews.

## Best practices

- If you are creating a new view in Html, use the available components over creating plain Html tags with Tailwind CSS classes.
- If you are making changes to an existing Html view, for example, an svg icon that is still implemented in plain Html, consider migrating it to use a ViewComponet.
- If you decide to create a new component, consider creating [previews](https://viewcomponent.org/guide/previews.html) for it as well. This will help others to discover your component with LookBook, also it makes it much eaier to test its different states.
