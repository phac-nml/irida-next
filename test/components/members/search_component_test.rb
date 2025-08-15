# frozen_string_literal: true

require 'test_helper'

class SearchComponentTest < ViewComponent::TestCase
  test 'Should render a searchbox' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'
    value = 'a value'
    label = 'a label'
    total_count = 0

    render_inline SearchComponent.new(
      query: Member.ransack,
      url:,
      search_attribute:,
      label:,
      placeholder:,
      total_count:,
      value:
    )

    assert_selector "form[action='#{url}']", count: 1
    assert_selector "label[for='q_#{search_attribute}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1
    assert_text label
    # NOTE: The value is not displayed as visible text, it's in the input value attribute
    assert_selector "input[value='#{value}']", count: 1
  end

  test 'accessibility' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'
    value = 'a value'
    label = 'a label'
    total_count = 0

    render_inline SearchComponent.new(
      query: Member.ransack,
      url:,
      search_attribute:,
      placeholder:,
      total_count:,
      value:,
      label:
    )

    # Test basic accessibility features
    assert_selector "form[action='#{url}']", count: 1
    assert_selector "label[for='q_#{search_attribute}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1
    assert_selector "input[type='search']", count: 1
    assert_selector "input[placeholder='#{placeholder}']", count: 1

    # Test that the component renders without errors
    assert_selector 'div[data-controller*="search-field"]', count: 1
    assert_selector 'form[data-turbo-action="replace"]', count: 1
  end

  test 'renders with different search attributes' do
    url = '/-/groups/group-1/-/members'
    placeholder = 'a placeholder'
    value = 'a value'
    label = 'a label'
    total_count = 0

    # Test different search attributes
    different_attributes = %i[user_email_cont name_cont puid_cont]

    different_attributes.each do |search_attribute|
      render_inline SearchComponent.new(
        query: Member.ransack,
        url:,
        search_attribute:,
        label:,
        placeholder:,
        total_count:,
        value:
      )

      assert_selector "form[action='#{url}']", count: 1
      assert_selector "input[id='q_#{search_attribute}']", count: 1
      assert_selector "label[for='q_#{search_attribute}']", count: 1
    end
  end

  test 'handles different values gracefully' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'
    label = 'a label'
    total_count = 0

    # Test with nil value
    render_inline SearchComponent.new(
      query: Member.ransack,
      url:,
      search_attribute:,
      label:,
      placeholder:,
      total_count:,
      value: nil
    )

    assert_selector "form[action='#{url}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1

    # Test with empty string value
    render_inline SearchComponent.new(
      query: Member.ransack,
      url:,
      search_attribute:,
      label:,
      placeholder:,
      total_count:,
      value: ''
    )

    assert_selector "form[action='#{url}']", count: 1
    assert_selector "input[id='q_#{search_attribute}']", count: 1

    # Test with custom value
    custom_value = 'custom@example.com'
    render_inline SearchComponent.new(
      query: Member.ransack,
      url:,
      search_attribute:,
      label:,
      placeholder:,
      total_count:,
      value: custom_value
    )

    assert_selector "form[action='#{url}']", count: 1
    assert_selector "input[value='#{custom_value}']", count: 1
  end

  test 'renders with content block' do
    url = '/-/groups/group-1/-/members'
    search_attribute = :user_email_cont
    placeholder = 'a placeholder'
    value = 'a value'
    label = 'a label'
    total_count = 0

    render_inline SearchComponent.new(
      query: Member.ransack,
      url:,
      search_attribute:,
      label:,
      placeholder:,
      total_count:,
      value:
    ) do
      '<div data-test="custom-content">Custom content</div>'.html_safe
    end

    assert_selector "form[action='#{url}']", count: 1
    assert_selector 'div[data-test="custom-content"]', count: 1
    assert_text 'Custom content'
  end
end
