# frozen_string_literal: true

# Ransack Sorting Helper
module SortingHelper
  def active_sort(ransack_obj, field, dir)
    return false unless ransack_obj.sorts.detect { |s| s && s.name == field.to_s && s.dir == dir.to_s }

    true
  end

  # Moved to ransack sort_links_component
  # def sorting_dropdown(ransack_obj, &)
  #   viral_dropdown(label: t(format('.sorting.%<field>s_%<dir>s',
  #                                  field: ransack_obj.sorts[0].name,
  #                                  dir: ransack_obj.sorts[0].dir)),
  #                  caret: true, &)
  # end

  def sorting_item(dropdown, ransack_obj, field, dir, sort_item)
    dropdown.with_item(label: t(format('.sorting.%<field>s_%<dir>s', field:, dir:)),
                       url: sort_url(ransack_obj, format('%<field>s %<dir>s', field:, dir:)).gsub(
                         "#{sort_item}.turbo_stream", sort_item
                       ),
                       icon_name: active_sort(ransack_obj, field, dir) ? 'check' : 'blank',
                       data: {
                         turbo_stream: true
                       })
  end
end
