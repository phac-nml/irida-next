---
sidebar_position: 1
id: code_review
title: Code Review Guidelines
---

This guide contains advice and best practices for performing code review, and having your code reviewed.

All merge requests for IRIDA Next, whether written by a IRIDA team member or a wider community member, must go through a code review process to ensure the code is effective, understandable, maintainable, and secure.

## Getting your pull request reviewed, approved, and merged

Before you begin:
* Familiarize yourself with the [contribution acceptance criteria](./pull_request_workflow#contribution-acceptance-criteria)

As soon as you have code to review, have the code **reviewed** by a reviewer. The reviewer can:
* Give you a second opinion on the chosen solution and implementation.
* Help look for bugs, logic problems, or uncovered edge cases.

Getting your pull request **merged** also requires a maintainer. If it requires more than one approval, the last maintainer to review and approve merges it.

### Acceptance checklist

This checklist encourages the authors, reviewers, and maintainers of pull requests (MRs) to confirm changes were analyzed for high-impact risks to quality, performance, reliability, security, observability, and maintainability.

Using checklists improves quality in software engineering. This checklist is a straightforward tool to support and bolster the skills of contributors to the IRIDA Next codebase.

#### Quality

1. You have self-reviewed this PR per [code review guidelines](./code_review).
1. For the code that this change impacts, you believe that the automated tests validate functionality that is highly important to users.
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

1. You have confirmed that if this PR contains a change to processing or storing credentials or tokens, authorization and authentication methods, you have added the `~security` label.

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
* Consider one-on-one chats or video calls if there are too many "I didn't understand" or "Alternative solution:" comments. Post a follow-up comment summarizing one-on-one discussion.
* If you ask a question to a specific person, always start the comment by mentioning them.

### Having your pull request reviewed

Please keep in mind that code review is a process that can take multiple iterations, and reviewers may spot things later that they may not have seen the first time.

* The first reviewer of your code is *you*. Before you perform that first push of your shiny new branch, read through the entire diff. Does it make sense? Did you include something unrelated to the overall purpose of the changes? Did you forget to remove any debugging code?
* Write a detailed description as outlined in the [pull request guidelines](./pull_request_workflow). Some reviewers may not be familiar with the feature or area of the codebase. Thorough descriptions help all reviewers understand your request and test effectively.
* If you know your change depends on another being merge first, note it in the description and set a dependency.
* Be grateful for reviewer's suggestions. ("Good call. I'll make that change.")
* Don't take it personally. The review is of the code, not of you.
* Explain why the code exists. ("It's like that because of these reasons. Would it be more clear if I rename this class/file/method/variable?")
* Extract unrelated changes and refactorings into future merge requests/issues.
* Seek to understand the reviewer's perspective.
* Try to respond to every comment.
* The merge request author resolves only the threads they have fully addressed. If there's an open reply, an open thread, a suggestion, a question, or anything else, the thread should be left to be resolved by the reviewer.
* It should not be assumed that all feedback requires their recommended changes to be incorporated into the PR before it is merged. It is a judgement call by the PR author and the reviewer as to if this is required, or if a follow-up issue should be created to address the feedback in the future after the PR in question is merged.
* Push commits based on earlier rounds of feedback as isolated commits to the branch. Do not squash until the branch is ready to merge. Reviewers should be able to read individual updates based on their earlier feedback.
* Request a new review from the reviewer once you are ready for another round of review.

### Requesting a review

When you are ready to have your pull request reviewed, you should request an initial review by selecting a reviewer based on the approval guidelines.

When a pull request has multiple areas for review, it is recommended that you specify which area a reviewer should be reviewing, and a which stage (first or second). This will help team members who qualify as reviewers for multiple areas to know which area they're being requested to review. For example a pull request has both `backend` and `frontend` concerns, you can mention the review in this manner: `@john_doe can you please review ~backend` or `@jane_doe could you please give this PR a ~frontend review?`

You can also use `ready for review` label. That means that your pull request is ready to be reviewed and any reviewer can pick it. It is recommended to use that label only if there isn’t time pressure and make sure the pull request is assigned to a reviewer.

It is the responsiblity of the author for the merge request to be reviewed. If it stays in the `ready for review` state too long it is recommended to request a review from a specific reviewer.

### Volunteering to review

IRIDA Next engineers who have the capacity can regularly check the list of [pull requests to review](https://github.com/phac-nml/irida-next/pulls?q=is%3Apr+is%3Aopen+label%3A%22ready+for+review%22+) and add themselves as a reviewer for any pull request they want to review.

### Reviewing a pull request

Understand why the change is necessary (fixes a bug, improves the user experience, refactors the existing code). Then:
* Try to be thorough in your reviews to reduce the number of iterations.
* Communicate which ideas you feel strongly about and those that you don't.
* Identify ways to simplify the code while still solving the problem.
* Offer alternative implementations, but assume the author already considered them. ("What do you think about using a custom validator here?")
* Seek to understand the authors perspective.
* Check out the branch, and test the changes locally. You can decide how much manual testing you want to perform. Your testing might result in opportunities to add automated tests.
* If you don't understand a piece of code, *say so*. There's a good chance someone else would be confused by it as well.
* Ensure the author is clear on what is required from them to address/resolve the suggestion.
  * Consider using the [Conventional Comment format](https://conventionalcomments.org/#format) to convey your intent.
  * For non-mandatory suggestions, decorate with (non-blocking) so the author knows they can optionally resolve within the pull request or follow-up at a later stage.
  * There's a [Chrome](https://chrome.google.com/webstore/detail/conventional-comments/pagggmojbbphjnpcjeeniigdkglamffk) and [Firefox](https://addons.mozilla.org/en-US/firefox/addon/conventional-comments/) add-on which you can use to apply [Conventional Comment](https://conventionalcomments.org) prefixes.
* Ensure there are not open dependencies.
* After a round of line notes, it can helpful to post a summary note such as "Looks good to me", or "Just a couple things to address."
* Let the author know if changes are required following your review.

### Merging a pull request

Before taking the decision to merge:
* Confirm that the correct PR type label is applied.
* Consider warnings and errors from code quality, and other reports. Unless a strong case can be made for the violation, these should be resolved before merging. A comment must be posted if the PR is merged with any failed job.

At least one maintainer must approve a PR before it can be merged. PR authors and people who add commits to a PR are not authorized to approve or merge the PR and must seek a maintainer who has not contributed to the PR to approve and merge it.

When ready to merge:
* Consider using the Squash and merge feature when the pull request has a lot of commits. When merging code, a maintainer should only use the squash feature if the author has already set this option, or if the merge request clearly contains a messy commit history, it will be more efficient to squash commits instead of circling back with the author about that. Otherwise if the PR only has a few commits, we'll be respecting the author's setting by not squashing them.


## Credits

Largely based on the [`gitlab` code review guide](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/code_review.md), which was largely based on the [`thoughtbot` code review guide](https://github.com/thoughtbot/guides/tree/master/code-review).
