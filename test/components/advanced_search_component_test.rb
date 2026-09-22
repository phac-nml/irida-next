# frozen_string_literal: true

require 'test_helper'

class AdvancedSearchComponentTest < ViewComponent::TestCase
  setup do
    @user = users(:john_doe)
    Current.user = @user
  end

  teardown do
    Current.user = nil
  end

  test 'version resolver selects the v2 implementation when the flag is enabled' do
    Flipper.enable(:advanced_search_v2, @user)

    assert_equal :v2, AdvancedSearchComponent::VERSION_RESOLVER.call
    assert_equal AdvancedSearch::V2::DialogComponent,
                 AdvancedSearchComponent::IMPLEMENTATIONS[:v2]
  end

  test 'version resolver selects the v1 implementation when the flag is disabled' do
    Flipper.disable(:advanced_search_v2, @user)

    assert_equal :v1, AdvancedSearchComponent::VERSION_RESOLVER.call
    assert_equal AdvancedSearch::V1::Component,
                 AdvancedSearchComponent::IMPLEMENTATIONS[:v1]
  end
end
