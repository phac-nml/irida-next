# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  module Samples
    # Test class for verifying lazy loading tabs functionality
    class TabsLazyLoadingTest < ApplicationSystemTestCase
      def setup
        @user = users(:john_doe)
        @project = projects(:project1)
        @sample = samples(:sample1)
        login_as @user
        visit namespace_project_sample_path(@project.namespace, @project, @sample)
      end

      test 'tabs component uses Pathogen::Tabs with lazy loading' do
        # Verify the new Pathogen::Tabs component is being used
        assert_selector '[role="tablist"]'
        assert_selector '[role="tab"]', count: 3
        assert_selector '[role="tabpanel"]', count: 3
      end

      test 'files tab content is directly rendered when navigating with query param' do
        visit namespace_project_sample_path(@project.namespace, @project, @sample, tab: 'files')

        # Content should be directly rendered, not in a turbo frame with loading
        assert_selector '#sample-attachments'
        assert_no_selector 'turbo-frame[loading="lazy"]#files-content'
      end

      test 'metadata tab content is directly rendered when navigating with query param' do
        visit namespace_project_sample_path(@project.namespace, @project, @sample, tab: 'metadata')

        # Content should be directly rendered
        assert_selector '#sample-metadata'
        assert_no_selector 'turbo-frame[loading="lazy"]#metadata-content'
      end

      test 'history tab content is directly rendered when navigating with query param' do
        visit namespace_project_sample_path(@project.namespace, @project, @sample, tab: 'history')

        # History component should be rendered
        assert_selector '[data-controller*="history"]'
        assert_no_selector 'turbo-frame[loading="lazy"]#history-content'
      end

      test 'tab switching works with keyboard navigation' do
        # Start on files tab
        first_tab = find('[role="tab"]', match: :first)
        first_tab.send_keys(:arrow_right)

        # Should move to metadata tab
        assert_selector '[role="tab"][aria-selected="true"]', text: I18n.t('projects.samples.show.tabs.metadata')
      end

      test 'URL hash is updated when switching tabs with sync_url enabled' do
        # Click on metadata tab
        click_button I18n.t('projects.samples.show.tabs.metadata')

        # Wait for URL to update
        assert_current_path namespace_project_sample_path(@project.namespace, @project, @sample,
                                                          anchor: 'metadata-tab')
      end
    end
  end
end
