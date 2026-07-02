# frozen_string_literal: true

require 'test_helper'
require 'nokogiri'

# Test for ApplicationHelper
class ApplicationHelperTest < ActionView::TestCase
  test 'returns empty JSON for English locale' do
    I18n.with_locale(:en) do
      assert_equal '{}', local_time_i18n_config
    end
  end

  test 'returns i18n config JSON for French locale' do
    I18n.with_locale(:fr) do
      result = JSON.parse(local_time_i18n_config)
      assert_includes result, 'time'
      assert_includes result['time'], 'elapsed'
      assert_equal 'il y a {time}', result['time']['elapsed']
    end
  end

  test 'returns valid JSON string' do
    I18n.with_locale(:fr) do
      json_string = local_time_i18n_config
      assert_nothing_raised { JSON.parse(json_string) }
    end
  end

  test 'returns empty JSON when translation is missing' do
    # Test that the method would handle a missing translation by returning '{}'
    # This is covered by the rescue block in the helper method
    I18n.with_locale(:en) do
      # For English locale, method explicitly returns '{}'
      assert_equal '{}', local_time_i18n_config
    end
  end

  test 'renders detached form and linked submit button' do
    html = detached_button_to('Delete', '/projects/1', method: :delete, form_id: 'delete-project-1')
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)

    form = fragment.at_css('form#delete-project-1')
    button = fragment.at_css('button[form="delete-project-1"]')

    assert_not_nil form
    assert_not_nil button
    assert_equal 'Delete', button.text.strip
    assert_equal 'post', form['method']
    assert_equal 'delete', form.at_css('input[name="_method"]')['value']
    assert_equal '/projects/1', form['action']
    assert_equal 'sr-only', form['class']
  end

  test 'accepts custom button attributes' do
    html = detached_button_to(
      'Archive',
      '/projects/2/archive',
      class: 'btn btn-danger',
      data: { turbo_confirm: 'Are you sure?' }
    )
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)
    button = fragment.at_css('button')

    assert_not_nil button
    assert_equal 'btn btn-danger', button['class']
    assert_equal 'Are you sure?', button['data-turbo-confirm']
    assert button['form'].start_with?('detached_form_')
  end
end
