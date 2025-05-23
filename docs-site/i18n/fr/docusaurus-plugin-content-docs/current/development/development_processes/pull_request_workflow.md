---
sidebar_position: 2
id: pull_request_workflow
title: Pull requests workflow
---

We welcome pull requests from everyone, with fixes and improvements to IRIDA Next code, tests, and documentation.

## Merge request guidelines for contributors

### Best practices

* If the change is non-trivial, we encourage you start a discussion with a team member. You can do this by tagging them in a PR before submitting the code for review. Taking to team embers can be helpful when making design decisions. Communicating the intent behind your changes can also help expedite pull request reviews.
* When having your code reviewed and when reviewing pull requests, please keep the [code review guidelines](./code_review) in mind.

### Keep it simple

Live by *smaller iterations*. Please keep the amount of changes in a single PR **as small as possible**. If you want to contribute a large feature, think very carefully about what the minimum viable change is. Can you split the functionality into two smaller PRs? Can you submit only the backend/API code? Can you start with a very simple UI? Can you do just a part of the refactor?

Small PRs which are more easily reviewed, lead to higher code quality which is more important to IRIDA Next than having a minimal commit log. The smaller a PR is, the more likely it will be merged quickly. After that you can send more PRs to enhance and expand the feature. The [How to get faster PR reviews](https://github.com/kubernetes/kubernetes/blob/release-1.5/docs/devel/faster_reviews.md) document from the Kubernetes team also has some great points regarding this.

## Contribution acceptance criteria

To make sure that your pull request can be approved, please ensure that it meets the contribution acceptance criteria below:

1. The change is as small as possible.
1. If the pull request contains more than 500 changes:
   * Explain the reason
1. Mention any major breaking changes.
1. Include proper tests and make sure all tests pass (unless it contains a test exposing a bug in existing code). Every new class should have corresponding unit tests, even if the class is exercised at a higher level, such as a feature test.
   * If a failing CI build seems to be unrelated to your contribution, you can try restarting the failing CI job, rebasing on top of target branch to bring in updates that may resolve the failure, or if it has not been fixed yet, ask a developer to help you fix the test.
1. The PR contains a few logically organized commits, or has squashing commits enabled.
1. The changes can merge without problems. If not, you should rebase if you're the only one working on your feature branch, otherwise merge the default branch into the PR branch.
1. Only one specific issue is fixed or one specific feature is implemented. Do not combine things; send separate pull requests for each issue or feature.
1. Migrations should do only one thing (for example, create a table, move data to a new table, or remove an old table) to aid retrying on failure.
1. Contains functionality that other users will benefit from.
1. Doesn't add configuration options or settings options since they complicate making and testing future changes.
1. Changes do not degrade performance:
   * Avoid repeated polling of endpoints that require a significant amount of overhead.
   * Check for N + 1 queries via the SQL log.
   * Avoid repeated access of the file system.
1. If the pull request adds any new libraries (like gems or JavaScript libraries), they should conform to our Licensing guidelines. Also, make the reviewer aware of the new library and explain why you need it.

## Definition of done

If you contribute to IRIDA Next, please know that changes involve more than just code. We use the following [definition of done](https://www.agilealliance.org/glossary/definition-of-done).

If a regression occurs, we prefer you revert the change. Your contribution is *incomplete* until you have made sure that it meets all these requirements.

### Functionality

1. Working and clean code that is commented where needed.
1. Documented in the `/docs` directory.
1. If your pull request adds one or more migrations, make sure to execute all migrations on a fresh database before the PR is reviewed. If the review leads to large changes in the PR, execute the migrations again after the review is complete.
1. If your pull request adds new validations to existing models, to make sure the data processing is backwards compatible:
   * Ask a IRIDA team member for assistance to execute the database query that checks the existing rows to ensure existing rows aren't impacted by the change.

### Testing

1. Unit, integration, and system tests that all pass on the CI server.
1. Regressions and bugs are covered with tests that reduce the risk of the issue happening again.
1. If your merge request adds one or more migrations, write tests for more complex migrations.

### UI changes

1. Use available components from the IRIDA Next Design System, Viral.
   * If adding a new Component it is preferred to submit that as a separate PR.
1. The PR must include *Before* and *After* screenshots if UI changes are made.
1. If the PR changes CSS classes, please include the list of affected pages, which can be found by running `grep css-class ./app -R`.

### Description of changes

1. Clear title and description explaining the relevancy of the contribution.
1. Description includes any steps or setup required to ensure reviewers can view the changes you've made.

### Approval

1. The [PR acceptance checklist](./code_review#acceptance-checklist) has been checked as confirmed in the PR.
1. Reviewed by relevant reviewers, and all concerns are addressed for Availability, Regressions, and Security. Documentation reviews should take place as soon as possible, but they should not block a merge request.
1. Your pull request has at least 1 approval, but depending on your changes might need additional approvals.
   * You don't have to select any specific reviewers, but you can if you really want specific people to approve your pull request.
1. Merged by a project maintainer.

## Related topics
* [Having your pull request reviewed](./code_review#having-your-pull-request-reviewed)
