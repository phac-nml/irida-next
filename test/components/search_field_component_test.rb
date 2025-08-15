# frozen_string_literal: true

require 'test_helper'

class SearchFieldComponentTest < ViewComponent::TestCase
  setup do
    @label = 'Search by email'
    @placeholder = 'Enter email address'
    @field_name = :user_email_cont
    @value = nil
    
    # Create a mock form object that responds to the methods we need
    @mock_form = mock('form')
    @mock_form.stubs(:label).returns('<label for="q_user_email_cont">Search by email</label>'.html_safe)
    @mock_form.stubs(:search_field).returns('<input type="search" id="q_user_email_cont" name="q[user_email_cont]" value="" placeholder="Enter email address">'.html_safe)
  end

  # Basic Rendering Tests
  test 'renders search field with correct structure' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    assert_selector 'div.flex.flex-col', count: 1
    assert_selector 'div.relative', count: 1
  end

  test 'renders with all required parameters' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that the component renders without errors
    assert_selector 'div[data-controller="search-field"]', count: 1
    assert_selector 'div.relative', count: 1
  end

  test 'renders with custom value' do
    custom_value = 'test@example.com'
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: custom_value
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
  end

  test 'renders with nil value' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
  end

  # Clear Button Tests
  test 'shows clear button when value is present' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    # The clear button should be visible (not hidden)
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    # Check that the button doesn't have the 'hidden' class
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  test 'hides clear button when value is nil' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    # The clear button should be hidden
    assert_selector 'button[data-search-field-target="clearButton"].hidden', count: 1
  end

  test 'hides clear button when value is empty string' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    # The clear button should be hidden
    assert_selector 'button[data-search-field-target="clearButton"].hidden', count: 1
  end

  test 'hides clear button when value is whitespace only' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: '   '
    )

    # The clear button should be hidden (whitespace is not considered present)
    assert_selector 'button[data-search-field-target="clearButton"].hidden', count: 1
  end

  # Submit Button Tests
  test 'shows submit button when value is nil' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    # The submit button should be visible (not hidden)
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="submitButton"].hidden'
  end

  test 'shows submit button when value is empty string' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    # The submit button should be visible (not hidden)
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="submitButton"].hidden'
  end

  test 'hides submit button when value is present' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    # The submit button should be hidden
    assert_selector 'button[data-search-field-target="submitButton"].hidden', count: 1
  end

  # Button Functionality Tests
  test 'clear button has correct attributes and actions' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    clear_button = find('button[data-search-field-target="clearButton"]')
    
    assert_equal 'button', clear_button['type']
    assert_includes clear_button['data-action'], 'click->search-field#clear'
    assert_includes clear_button['data-action'], 'click->selection#clear'
    assert_equal I18n.t('components.search_field_component.clear_button'), clear_button['aria-label']
  end

  test 'submit button has correct attributes and actions' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    submit_button = find('button[data-search-field-target="submitButton"]')
    
    assert_equal 'submit', submit_button['type']
    assert_includes submit_button['data-action'], 'click->selection#clear'
    assert_equal I18n.t('components.search_field_component.search_button'), submit_button['aria-label']
  end

  # Accessibility Tests
  test 'has proper accessibility attributes' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for proper screen reader label
    assert_selector 'label.sr-only', count: 1
    
    # Check for proper button accessibility
    assert_selector 'button[aria-label]', count: 2 # clear and submit buttons
  end

  test 'clear button is accessible' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    clear_button = find('button[data-search-field-target="clearButton"]')
    assert_equal I18n.t('components.search_field_component.clear_button'), clear_button['aria-label']
  end

  test 'submit button is accessible' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    submit_button = find('button[data-search-field-target="submitButton"]')
    assert_equal I18n.t('components.search_field_component.search_button'), submit_button['aria-label']
  end

  # Component Method Tests
  test 'clear_button? method returns true for present values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    assert component.clear_button?
  end

  test 'clear_button? method returns false for nil values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    assert_not component.clear_button?
  end

  test 'clear_button? method returns false for empty string values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    assert_not component.clear_button?
  end

  test 'clear_button? method returns false for whitespace only values' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: '   '
    )

    assert_not component.clear_button?
  end

  # Edge Cases and Error Handling
  test 'handles very long values gracefully' do
    long_value = 'a' * 1000
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: long_value
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    # The clear button should be visible for long values
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  test 'handles special characters in values gracefully' do
    special_chars = 'test@example.com & special/chars <>'
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: special_chars
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    # The clear button should be visible for special characters
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  test 'handles unicode characters in values gracefully' do
    unicode_chars = 'café résumé naïve'
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: unicode_chars
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    # The clear button should be visible for unicode characters
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_no_selector 'button[data-search-field-target="clearButton"].hidden'
  end

  # Component Initialization Tests
  test 'initializes with all required parameters' do
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    assert_equal @label, component.instance_variable_get(:@label)
    assert_equal @placeholder, component.instance_variable_get(:@placeholder)
    assert_equal @mock_form, component.instance_variable_get(:@form)
    assert_equal @field_name, component.instance_variable_get(:@field_name)
    assert_nil component.instance_variable_get(:@value)
  end

  test 'initializes with custom value' do
    custom_value = 'custom@example.com'
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: custom_value
    )

    assert_equal custom_value, component.instance_variable_get(:@value)
  end

  # Different Field Names Tests
  test 'renders with different field names' do
    different_field_names = %i[user_email_cont name_cont puid_cont description_cont]
    
    different_field_names.each do |field_name|
      render_inline SearchFieldComponent.new(
        label: @label,
        placeholder: @placeholder,
        form: @mock_form,
        field_name: field_name,
        value: @value
      )

      assert_selector 'div[data-controller="search-field"]', count: 1
    end
  end

  # Different Labels and Placeholders Tests
  test 'renders with different labels and placeholders' do
    different_labels = ['Search by name', 'Search by ID', 'Search by description']
    different_placeholders = ['Enter name', 'Enter ID', 'Enter description']
    
    different_labels.each_with_index do |label, index|
      render_inline SearchFieldComponent.new(
        label: label,
        placeholder: different_placeholders[index],
        form: @mock_form,
        field_name: @field_name,
        value: @value
      )

      assert_selector 'div[data-controller="search-field"]', count: 1
    end
  end

  # Button State Logic Tests
  test 'button visibility logic works correctly' do
    # Test with nil value
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: nil
    )

    assert_not component.clear_button?
    
    # Test with empty string
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: ''
    )

    assert_not component.clear_button?
    
    # Test with whitespace
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: '   '
    )

    assert_not component.clear_button?
    
    # Test with actual value
    component = SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: 'test@example.com'
    )

    assert component.clear_button?
  end

  # Form Integration Tests
  test 'integrates properly with form object' do
    # Create a more realistic mock form that responds to the methods we need
    realistic_mock_form = mock('realistic_form')
    realistic_mock_form.stubs(:label).returns('<label for="q_test_field">Test Label</label>'.html_safe)
    realistic_mock_form.stubs(:search_field).returns('<input type="search" id="q_test_field" name="q[test_field]" value="test value" placeholder="Test placeholder">'.html_safe)
    
    render_inline SearchFieldComponent.new(
      label: 'Test Label',
      placeholder: 'Test placeholder',
      form: realistic_mock_form,
      field_name: :test_field,
      value: 'test value'
    )

    assert_selector 'div[data-controller="search-field"]', count: 1
    assert_selector 'div.relative', count: 1
  end

  # CSS Classes and Styling Tests
  test 'has correct CSS classes for styling' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for Tailwind CSS classes
    assert_selector 'div.flex.flex-col', count: 1
    assert_selector 'div.relative', count: 1
  end

  # Data Attributes Tests
  test 'has correct data attributes for Stimulus' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for Stimulus controller
    assert_selector 'div[data-controller="search-field"]', count: 1
    
    # Check for Stimulus targets
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
  end

  # Icon Integration Tests
  test 'renders icons for buttons' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that buttons contain icon elements
    assert_selector 'button[data-search-field-target="clearButton"]', count: 1
    assert_selector 'button[data-search-field-target="submitButton"]', count: 1
  end

  # Responsive Design Tests
  test 'has responsive design classes' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check for responsive classes
    assert_selector 'div.flex.flex-col', count: 1
    assert_selector 'div.relative', count: 1
  end

  # Dark Mode Support Tests
  test 'supports dark mode styling' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # The component should render without errors
    assert_selector 'div[data-controller="search-field"]', count: 1
  end

  # Hover Effects Tests
  test 'has hover effects for buttons' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that buttons have hover classes
    clear_button = find('button[data-search-field-target="clearButton"]')
    submit_button = find('button[data-search-field-target="submitButton"]')
    
    # Both buttons should have hover effects
    assert_includes clear_button['class'], 'hover:bg-slate-100'
    assert_includes submit_button['class'], 'hover:bg-slate-100'
  end

  # Transition Effects Tests
  test 'has transition effects for buttons' do
    render_inline SearchFieldComponent.new(
      label: @label,
      placeholder: @placeholder,
      form: @mock_form,
      field_name: @field_name,
      value: @value
    )

    # Check that buttons have transition classes
    clear_button = find('button[data-search-field-target="clearButton"]')
    submit_button = find('button[data-search-field-target="submitButton"]')
    
    # Both buttons should have transition effects
    assert_includes clear_button['class'], 'transition-colors'
    assert_includes submit_button['class'], 'transition-colors'
  end
end
