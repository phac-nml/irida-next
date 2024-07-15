# frozen_string_literal: true

# Ransack Sorting Helper
module SortingHelper
  def active_sort(ransack_obj, field, dir)
    return false unless ransack_obj.sorts.detect { |s| s && s.name == field.to_s && s.dir == dir.to_s }

    true
  end

  def sorting_item(dropdown, ransack_obj, field, dir)
    dropdown.with_item(label: t(format('.sorting.%<field>s_%<dir>s', field:, dir:)),
                       url: sorting_url(ransack_obj, field, dir:),
                       icon_name: active_sort(ransack_obj, field, dir) ? 'check' : 'blank',
                       data: {
                         turbo_stream: true
                       })
  end

  def sorting_url(ransack_obj, field, dir: nil)
    url = if dir.nil?
            sort_url(ransack_obj,
                     field).to_s
          else
            sort_url(ransack_obj, format('%<field>s %<dir>s', field:, dir:)).to_s
          end
    url.include?('.turbo_stream') ? url.gsub!('.turbo_stream', '') : url

    # encode field and dir to result in parmas looking like this: "q[s]=field+dir"
    # "?q%5Bs%5D=#{field}+#{dir}"
  end
end
