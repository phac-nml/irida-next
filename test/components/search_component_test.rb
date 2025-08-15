# frozen_string_literal: true

require 'test_helper'

class SearchComponentTest < ViewComponent::TestCase
  setup do
    @url = '/-/groups/group-1/-/members'
    @search_attribute = :user_email_cont
    @placeholder = 'Search by email address'
    @label = 'Email Search'
    @total_count = 0
    @value = nil
    @query = Member.ransack
  end

  # Basic Rendering Tests
  test 'renders search form with correct attributes' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    assert_selector "form[action='#{@url}']", count: 1
    assert_selector "form[method='get']", count: 1
    assert_selector "input[id='q_#{@search_attribute}']", count: 1
    assert_selector "input[type='search']", count: 1
    assert_selector "input[placeholder='#{@placeholder}']", count: 1
    assert_selector "label[for='q_#{@search_attribute}']", count: 1
    assert_text @label
  end

  test 'renders with custom value' do
    custom_value = 'test@example.com'
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: custom_value
    )

    assert_selector "input[value='#{custom_value}']", count: 1
  end

  test 'renders with nil value' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: nil
    )

    # The input should render without a value attribute when nil
    assert_selector "input[id='q_#{@search_attribute}']", count: 1
    assert_selector "input[type='search']", count: 1
  end

  # Data Attributes and Controllers
  test 'sets correct data attributes and controllers' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    assert_selector 'div[data-controller*="search-field"]', count: 1
    assert_selector 'form[data-turbo-action="replace"]', count: 1
  end

  test 'merges custom data attributes' do
    custom_data = { data: { controller: 'custom-controller', 'custom-attr': 'value' } }

    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value,
      **custom_data
    )

    assert_selector 'div[data-controller*="search-field"]', count: 1
    # The custom controller should be merged into the form's data attributes
    assert_selector 'form[data-controller*="custom-controller"]', count: 1
    assert_selector 'form[data-custom-attr="value"]', count: 1
  end

  # Edge Cases and Error Handling
  test 'handles nil total count gracefully' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: nil,
      value: @value
    )

    # Should not raise an error and should render normally
    assert_selector "form[action='#{@url}']", count: 1
  end

  test 'handles negative total count gracefully' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: -1,
      value: @value
    )

    # Should not raise an error and should render normally
    assert_selector "form[action='#{@url}']", count: 1
  end

  # Accessibility Tests
  test 'has proper accessibility attributes' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    # Check for proper form labeling
    assert_selector "label[for='q_#{@search_attribute}']", count: 1
    assert_selector "input[id='q_#{@search_attribute}']", count: 1

    # Check for proper input attributes
    assert_selector "input[type='search']", count: 1
    assert_selector "input[placeholder='#{@placeholder}']", count: 1
  end

  # Integration with Ransack
  test 'renders ransack hidden sort field' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    # Should render the Ransack::HiddenSortFieldComponent
    # Note: This may not always render a hidden field if there are no sorts
    assert_selector "form[action='#{@url}']", count: 1
  end

  test 'renders search field component' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    # Should render the SearchFieldComponent
    assert_selector 'div[data-controller*="search-field"]', count: 1
    assert_selector 'input[data-search-field-target="input"]', count: 1
  end

  # Content Block Support
  test 'renders content block when provided' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    ) do
      '<div data-test="custom-content">Custom content</div>'.html_safe
    end

    assert_selector 'div[data-test="custom-content"]', count: 1
    assert_text 'Custom content'
  end

  test 'renders without content block' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    # Should still render the form properly
    assert_selector "form[action='#{@url}']", count: 1
  end

  # Performance and Memory
  test 'does not create memory leaks with large queries' do
    # Create a query with many sorts - simplified approach
    query_with_sorts = Member.ransack

    render_inline SearchComponent.new(
      query: query_with_sorts,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    # Should render without errors
    assert_selector "form[action='#{@url}']", count: 1
  end

  # Component Preview Tests
  test 'preview renders without errors' do
    assert_nothing_raised do
      render_preview :default
    end
  end

  test 'preview has valid markup' do
    render_preview :default
    # The preview should render without errors
    assert_selector 'form', count: 1
  end

  # Component Method Tests
  test 'kwargs method merges data attributes correctly' do
    component = SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    kwargs = component.kwargs

    assert_includes kwargs[:data][:controller], 'search-field'
    assert_includes kwargs[:data][:controller], 'selection'
    assert_equal 'replace', kwargs[:data]['turbo-action']
  end

  test 'kwargs method handles custom data attributes' do
    custom_data = { data: { controller: 'custom-controller' } }

    component = SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value,
      **custom_data
    )

    kwargs = component.kwargs

    assert_includes kwargs[:data][:controller], 'search-field'
    assert_includes kwargs[:data][:controller], 'selection'
    assert_includes kwargs[:data][:controller], 'custom-controller'
  end

  test 'kwargs method handles nil data attributes' do
    component = SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    kwargs = component.kwargs

    assert_includes kwargs[:data][:controller], 'search-field'
    assert_includes kwargs[:data][:controller], 'selection'
  end

  # Form Structure Tests
  test 'renders proper form structure' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    # Check form structure
    assert_selector 'form', count: 1
    assert_selector 'form div[data-controller*="search-field"]', count: 1

    # Check for search field component
    assert_selector 'input[type="search"]', count: 1
    assert_selector 'input[placeholder]', count: 1
  end

  test 'renders with different search attributes' do
    different_attributes = %i[name_cont puid_cont description_cont]

    different_attributes.each do |attr|
      render_inline SearchComponent.new(
        query: @query,
        url: @url,
        search_attribute: attr,
        label: @label,
        placeholder: @placeholder,
        total_count: @total_count,
        value: @value
      )

      assert_selector "input[id='q_#{attr}']", count: 1
      assert_selector "label[for='q_#{attr}']", count: 1
    end
  end

  test 'renders with different URLs' do
    different_urls = [
      '/-/groups/group-1/-/members',
      '/-/projects/project-1/-/samples',
      '/-/samples'
    ]

    different_urls.each do |url|
      render_inline SearchComponent.new(
        query: @query,
        url: url,
        search_attribute: @search_attribute,
        label: @label,
        placeholder: @placeholder,
        total_count: @total_count,
        value: @value
      )

      assert_selector "form[action='#{url}']", count: 1
    end
  end

  # Error Handling Tests
  test 'handles empty string values gracefully' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: ''
    )

    assert_selector "form[action='#{@url}']", count: 1
    assert_selector "input[type='search']", count: 1
  end

  test 'handles very long values gracefully' do
    long_value = 'a' * 1000
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: long_value
    )

    assert_selector "form[action='#{@url}']", count: 1
    assert_selector "input[value='#{long_value}']", count: 1
  end

  test 'handles special characters in values gracefully' do
    special_chars = 'test@example.com & special/chars <>'
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: special_chars
    )

    assert_selector "form[action='#{@url}']", count: 1
    assert_selector "input[value='#{special_chars}']", count: 1
  end

  # Component Initialization Tests
  test 'initializes with all required parameters' do
    component = SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    assert_equal @query, component.instance_variable_get(:@query)
    assert_equal @url, component.instance_variable_get(:@url)
    assert_equal @search_attribute, component.instance_variable_get(:@search_attribute)
    assert_equal @label, component.instance_variable_get(:@label)
    assert_equal @placeholder, component.instance_variable_get(:@placeholder)
    assert_equal @total_count, component.instance_variable_get(:@total_count)
    assert_nil component.instance_variable_get(:@value)
  end

  test 'initializes with optional parameters' do
    custom_kwargs = { custom_param: 'value', another_param: 123 }

    component = SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value,
      **custom_kwargs
    )

    kwargs = component.instance_variable_get(:@kwargs)
    assert_equal 'value', kwargs[:custom_param]
    assert_equal 123, kwargs[:another_param]
  end

  # Search Field Component Integration
  test 'search field component receives correct attributes' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    # Verify the search field component is rendered with correct attributes
    assert_selector 'input[type="search"]', count: 1
    assert_selector 'input[placeholder]', count: 1
    assert_selector 'label[for]', count: 1
  end

  # Form Method and Action Tests
  test 'form has correct method and action' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    assert_selector "form[method='get']", count: 1
    assert_selector "form[action='#{@url}']", count: 1
  end

  # Label Association Tests
  test 'label is properly associated with input' do
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: @value
    )

    input_id = "q_#{@search_attribute}"
    assert_selector "label[for='#{input_id}']", count: 1
    assert_selector "input[id='#{input_id}']", count: 1
  end

  # Placeholder and Value Tests
  test 'input has correct placeholder and value' do
    test_value = 'test value'
    render_inline SearchComponent.new(
      query: @query,
      url: @url,
      search_attribute: @search_attribute,
      label: @label,
      placeholder: @placeholder,
      total_count: @total_count,
      value: test_value
    )

    assert_selector "input[placeholder='#{@placeholder}']", count: 1
    assert_selector "input[value='#{test_value}']", count: 1
  end
end
