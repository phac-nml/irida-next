# frozen_string_literal: true

json.next_cursor @cursor_page.next_cursor
json.rows @samples.each_with_index.to_a do |sample, index|
  row_index = @cursor_page.row_offset + index
  json.index row_index
  json.html render(
    Samples::Table::V2::RowComponent.new(
      sample, @project.namespace, global_row_index: row_index,
                                  metadata_fields: @fields, search_params: @search_params
    )
  )
end
