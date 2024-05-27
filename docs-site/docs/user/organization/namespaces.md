---
sidebar_position: 1
id: namespaces
title: Namespaces
---

In IRIDA Next, a _namespace_ provides one place to organize your related projects. Projects in one namespace are separate from projects in other namespaces, which means you can use the same name for projects in different namespaces.

## Types of namespaces

IRIDA Next has two types of namespaces:
* A _personal_ namespace, which is based on your email address and provided to you when you create your account.
  * You cannot create subgroups in a personal namespace.
  * Groups in your namespace do not inherit your namespace permissions and group features.
  * All the projects you create are under the scope of this namespace.
  * If you change your email address, the project and namespace URLs in your account also change.
* A _group_ or _subgroup_ namespace, which is based on the group or subgroup name:
  * You can create multiple subgroups to manage multiple projects.
  * You can configure settings specifically for each subgroup and project in the namespace.
  * You can change the URL of group and subgroup namespaces.

## Determine which type of namespace you're viewing

To determine whether you're viewing a group or personal namespace, you can view the URL. For example:

| Namespace for           | Url                     | Namespace               |
|:------------------------|:------------------------|:------------------------|
| A user with email address `john.doe@example.com` | `https://irida-next.example.com/john.doe_at_example.com` | `john.doe_at_example.com` |
| A group named `pathogen` | `https://irida-next.example.com/pathogen` | `pathogen` |
| A group named `pathogen` with a subgroup named `surveillance` | `https://irida-next.example.com/pathogen/surveillance` | `pathogen/surveillance` |

## Naming limitations for namespaces

When choosing a name for your namespace, keep in mind the [character limitations](../project/projects/reserved-names#limitations-on-projects-and-groups),  [reserved group names](../organization/groups/reserved-names) and [reserved project names](../project/projects/reserved-names).
