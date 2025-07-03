# frozen_string_literal: true

module GroupsDashboard
  class InformationComponentPreview < ViewComponent::Preview
    # Default Preview
    # ---------------
    # This is the default preview for the Groups::Dashboard::InformationComponent.
    # It shows a group with a description and statistics.
    def default
      group = Group.new(
        name: 'Test Group',
        description: 'This is a test group description that provides some information about the group.',
        created_at: 1.month.ago
      )
      stub_group_counts(group, samples: 42, members: 5, projects: 3, subgroups: 0)

      render(GroupsDashboard::InformationComponent.new(group:))
    end

    # Without Description
    # ------------------
    # This preview shows the component without a group description.
    def without_description
      group = Group.new(
        name: 'Test Group',
        description: nil,
        created_at: 1.month.ago
      )
      stub_group_counts(group, samples: 42, members: 5, projects: 3, subgroups: 0)

      render(GroupsDashboard::InformationComponent.new(group:))
    end

    # With Empty Counts
    # -----------------
    # This preview shows the component with all counts set to zero.
    def with_empty_counts
      group = Group.new(
        name: 'Empty Group',
        description: 'This group has no content yet.',
        created_at: 1.week.ago
      )
      stub_group_counts(group, samples: 0, members: 0, projects: 0, subgroups: 0)

      render(GroupsDashboard::InformationComponent.new(group:))
    end

    private

    def stub_group_counts(group, samples:, members:, projects:, subgroups: 0)
      group.define_singleton_method(:samples_count) { samples }

      group_members = []
      members.times { group_members << Object.new }
      group.define_singleton_method(:group_members) { group_members }

      project_namespaces = []
      projects.times { project_namespaces << Object.new }
      group.define_singleton_method(:project_namespaces) { project_namespaces }

      children = []
      subgroups.times { children << Object.new }
      group.define_singleton_method(:children) { children }
    end
  end
end
