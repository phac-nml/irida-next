---
sidebar_position: 1
id: code_review
title: Code Review Guidelines
---

This guide contains advice and best practices for performing code review, and having your code reviewed.

All merge requests for IRIDA Next, whether written by a IRIDA team member or a wider community member, must go through a code review process to ensure the code is effective, understandable, maintainable, and secure.

## Getting your pull request reviewed, approved, and merged

Before you begin:
* Familiarize yourself with the [contribution acceptance criteria](./pull_request_workflow/)#contribution-acceptance-criteria

As soon as you have code to review, have the code **reviewed** by a reviewer. The reviewer can:
* Give you a second opinion on the chosen solution and implementation.
* Help look for bugs, logic problems, or uncovered edge cases.

Getting your pull request **merged** also requires a maintainer. If it requires more than one approval, the last maintainer to review and approve merges it.

### Acceptance checklist

This checklist encourages the authors, reviewers, and maintainers of pull requests (MRs) to confirm changes were analyzed for high-impact risks to quality, performance, reliability, security, observability, and maintainability.

Using checklists improves quality in software engineering. This checklist is a straightforward tool to support and bolster the skills of contributors to the IRIDA Next codebase.

#### Quality

1. You have self-reviewed this PR per [code review guidelines](./code_review).
1. For the code that this change impacts, you beloeve that the automated tests validated functionality that is highly important to users.
1. If the existing automated tests do not cover the above functionality, you have added the necessary tests or added an issue to describe the automation testing gap and linked it to this PR.
1. You have considered the technical aspects of this change's impact on IRIDA Next.
1. You have considered the impact of this change on the frontend, backend, and database portions of the system where appropriate and applied the `~ux`, `~frontend`, `~backend`, and `~database` labels accordingly.

#### Performance, reliability, and availability

1. You are confident that this PR does not harm performance, or you have asked a reviewer to help assess the performance impact.
1. You have added information for database reviewers in the PR description, or you have decided that it is unnecessary.
1. You have considered the scalability risk based on future predicted growth.

#### Documentation

1. You have added/updated documentation or decided that documentation changes are unnecessary for this PR.

#### Security

1. You have confirmed that if thsi PR contains a change to processing or storing credentials or tokens, authorization and authentication methods, you have added the `~security` label.

## Best practices

### Everyone

* Be kind.
* Accept that many programming decisions are opinions. Discuss tradeoffs, which you prefer, and reach a resolution quickly.
* Ask questions; don't make demands. ("What do you think about naming this `:sample_id`?")
* Ask for clarification. ("I didn't understand. Can you clarify?")
* Avoid selective ownership of code. ("mine", "not mine", "yours")
* Avoid using terms that could be seen as referring to personal traits. ("dumb", "stupid"). Assume everyone is intelligent and well-meaning.
* Be explicit. Remember people don't always understand your intentions online.
* Be humble. ("I'm not sure - let's look it up.")
* Don't use hyperbole. ("always", "never", "endlessly", "nothing")
* Be careful about the use of sarcasm. Everything we do is public; what seems like good-natured ribbing to you and a long-time colleague might come off as mean and unwelcoming to a person new to the project.
* Consider one-on-one chats or video valls if there are too many "I didn't understand" or "Alternative solution:" comments. Post a follow-up comment summarizing one-on-one discussion.
* If you ask a question to a specific person, always start the comment by mentioning them.

### Having your pull request reviewed

Please keep in mind that code review is a process that can take multiple iterations, and reviewers may spot things later that they may not have seen the first time.

* The first reviewer of your code is *you*

### Credits

Largely based on the [`gitlab` code review guide](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/code_review.md), which was largely based on the [`thoughtbot` code review guide](https://github.com/thoughtbot/guides/tree/master/code-review).
