# frozen_string_literal: true

require 'ransack/helpers/form_helper'

# Ransack Sorting Helper
module SortingHelper
  def active_sort(ransack_obj, field, dir)
    return false unless ransack_obj.sorts.detect { |s| s && (s.attr_name.nil? ? s.name : s.attr_name) == field.to_s && s.dir == dir.to_s }

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

  def sorting_url(ransack_obj, field, dir: nil, with_search_params: true)
    if dir.nil?
      dir = active_sort(ransack_obj, field, :asc) ? :desc : :asc
    end
    url = if with_search_params
              sort_url(ransack_obj, format('%<field>s %<dir>s', field:, dir:)).to_s
          else
            url_for(Ransack::Helpers::FormHelper::SortLink.new(ransack_obj, field, { dir: },
                                                               params.except(:q)).url_options)
          end
    url.include?('.turbo_stream') ? url.gsub!('.turbo_stream', '') : url
  end
end
