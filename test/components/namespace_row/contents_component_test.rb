# frozen_string_literal: true

require 'test_helper'

module NamespaceRow
  class ContentsComponentTest < ViewComponent::TestCase
    test 'renders tooltips with left placement for group namespace' do
      namespace = groups(:group_one)
      with_request_url '/-/groups/group-1' do
        render_inline(
          ContentsComponent.new(
            namespace:,
            full_name: false,
            icon_size: :small,
            search_params: nil
          )
        )

        # Verify all tooltips use left placement
        assert_selector 'div[data-placement="left"]', count: 3
        # Verify tooltip controller is present
        assert_selector 'div[data-controller="pathogen--tooltip"]', minimum: 3
      end
    end

    test 'renders tooltip with left placement for project namespace' do
      project = projects(:project1)
      namespace = project.namespace
      with_request_url '/group-1/project-1' do
        render_inline(
          ContentsComponent.new(
            namespace:,
            full_name: false,
            icon_size: :small,
            search_params: nil
          )
        )

        # Verify tooltip uses left placement (changed from :right)
        assert_selector 'div[data-placement="left"]', count: 1
        # Verify tooltip controller is present
        assert_selector 'div[data-controller="pathogen--tooltip"]', minimum: 1
      end
    end

    test 'tooltips have proper ARIA attributes' do
      namespace = groups(:group_one)
      with_request_url '/-/groups/group-1' do
        render_inline(
          ContentsComponent.new(
            namespace:,
            full_name: false,
            icon_size: :small,
            search_params: nil
          )
        )

        # Verify tooltips have role="tooltip"
        assert_selector 'div[role="tooltip"]', minimum: 3
        # Verify links have aria-describedby
        assert_selector 'a[aria-describedby]', minimum: 3
      end
    end
  end
end
