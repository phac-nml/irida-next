# frozen_string_literal: true

module SystemTestUiHelper
  def select_select2_option(option_value:, query: nil, input_selector: 'input.select2-input')
    find(input_selector).click
    find(input_selector).fill_in with: query if query.present?

    option_selector = "li[data-value='#{option_value}']"
    assert_selector option_selector
    find(option_selector, match: :first).click
  end

  def first_table_row_cell_text(table_selector: 'table', cell_index: 2)
    within("#{table_selector} tbody tr:first-child") do
      find("td:nth-child(#{cell_index})").text
    end
  end
end
