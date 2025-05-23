---
id: accessibility
sidebar_position: 1
---

# Accessibility

Accessibility is important for users who use screen readers or rely on keyboard-only functionality to ensure they have an equivalent experience to sighted mouse users.

## Testing

We use [axe-core](https://github.com/dequelabs/axe-core) for accessibility testing in our system test cases. You can call `assert_accessible` at any point which will run `axe-core` and report any accesibility errors found. Note: This is automatically called when `fill_in` or `visit` helpers are called in the tests.
