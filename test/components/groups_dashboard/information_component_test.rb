# frozen_string_literal: true

require 'view_component_test_case'

module GroupsDashboard
  class InformationComponentTest < ViewComponentTestCase
    test 'renders group description when present' do
      group = Group.new(
        name: 'Test Group',
        description: 'Test description',
        created_at: Time.zone.now
      )
      stub_group_counts(group, samples: 1, members: 2, projects: 3, subgroups: 4)

      render_inline(GroupsDashboard::InformationComponent.new(group:))

      assert_selector 'dt', text: I18n.t('groups.show.information.description')
      assert_selector 'dd', text: 'Test description'
    end

    test 'does not render description section when description is blank' do
      group = Group.new(
        name: 'Test Group',
        description: nil,
        created_at: Time.zone.now
      )
      stub_group_counts(group, samples: 1, members: 2, projects: 3, subgroups: 0)

      render_inline(GroupsDashboard::InformationComponent.new(group:))

      assert_no_selector 'dt', text: I18n.t('groups.show.information.description')
    end

    test 'renders all statistics with correct values' do
      created_at = Time.zone.now
      group = Group.new(
        name: 'Test Group',
        description: 'Test description',
        created_at: created_at
      )
      stub_group_counts(group, samples: 10, members: 20, projects: 30, subgroups: 40)

      render_inline(GroupsDashboard::InformationComponent.new(group:))

      # Test samples count
      assert_selector 'h3',
                      text: I18n.t('groups.show.information.number_of_samples')
      assert_selector '[aria-describedby*="statistic-label-ns-stat-group-samples-"]', text: '10'

      # Test projects count
      assert_selector 'h3',
                      text: I18n.t('groups.show.information.number_of_projects')
      assert_selector '[aria-describedby*="statistic-label-ns-stat-group-projects-"]', text: '30'

      # Test subgroups count
      assert_selector 'h3',
                      text: I18n.t('groups.show.information.number_of_subgroups')
      assert_selector '[aria-describedby*="statistic-label-ns-stat-group-subgroups-"]', text: '40'
    end

    test 'renders with zero counts' do
      created_at = Time.zone.now
      group = Group.new(
        name: 'Empty Group',
        description: 'No content',
        created_at: created_at
      )
      stub_group_counts(group, samples: 0, members: 0, projects: 0, subgroups: 0)

      # Wrap in a container div to ensure valid HTML structure
      render_inline(
        GroupsDashboard::InformationComponent.new(group:)
      )

      # Check that the component renders with zero values
      assert_selector '[aria-describedby*="statistic-label-ns-stat-group-samples-"]', text: '0'
      assert_selector '[aria-describedby*="statistic-label-ns-stat-group-projects-"]', text: '0'
      assert_selector '[aria-describedby*="statistic-label-ns-stat-group-subgroups-"]', text: '0'
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
