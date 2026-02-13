# frozen_string_literal: true

module SortingTestHelper
  def assert_sort_state(column_index, direction, table_selector: 'table')
    assert_select "#{table_selector} thead th:nth-child(#{column_index})[aria-sort=\"#{direction}\"]", 1
  end

  def assert_first_rows_include(first_text, second_text, row_scope: 'table tbody')
    doc = Nokogiri::HTML(response.body)
    first_row = doc.at_css("#{row_scope} tr:first-child")
    second_row = doc.at_css("#{row_scope} tr:nth-child(2)")

    assert_includes first_row&.text.to_s, first_text.to_s
    assert_includes second_row&.text.to_s, second_text.to_s
  end
end
