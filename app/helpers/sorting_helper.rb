# frozen_string_literal: true

require 'ransack/helpers/form_helper'

# Ransack Sorting Helper
module SortingHelper
  def active_sort(ransack_obj, field, dir)
    return false unless ransack_obj.sorts.detect { |s| s && s.name == field.to_s && s.dir == dir.to_s }

    true
  end

  def sorting_item(dropdown, ransack_obj, field, dir, disableable = true)
    dropdown.with_item(label: t(format('.sorting.%<field>s_%<dir>s', field:, dir:)),
                       url: sorting_url(ransack_obj, field, dir:),
                       disableable: disableable,
                       params: disableable ? set_params(field, dir) : {},
                       icon_name: active_sort(ransack_obj, field, dir) ? 'check' : 'blank',
                       data: {
                         turbo_stream: true
                       })
  end

  def sorting_url(ransack_obj, field, dir: nil, with_search_params: true)
    url = if with_search_params
            if dir.nil?
              sort_url(ransack_obj,
                       field).to_s
            else
              sort_url(ransack_obj, format('%<field>s %<dir>s', field:, dir:)).to_s
            end
          else
            url_for(Ransack::Helpers::FormHelper::SortLink.new(ransack_obj, field, { dir: },
                                                               params.except(:q)).url_options)
          end
    url.include?('.turbo_stream') ? url.gsub!('.turbo_stream', '') : url
  end

  # 🔍 Generates ARIA sort attributes for table column headers
  #
  # @param column [String, Symbol] 📊 The column identifier
  # @param sort_key [String] 🔑 The current sort column
  # @param sort_direction [String] ⬆️ The current sort direction ('asc' or 'desc')
  #
  # @return [Hash] 🏷️ A hash of ARIA attributes for the column header
  #   - Returns empty hash if column is not currently sorted
  #   - Returns { 'aria-sort': 'ascending' } or { 'aria-sort': 'descending' } if sorted
  #
  # @example Setting ARIA attributes on a column header
  #   <%= content_tag :th, **aria_sort('name', params[:sort], params[:direction]) %>
  def aria_sort(column, sort_key, sort_direction)
    return {} unless sort_key.present? && sort_key == column.to_s

    { 'aria-sort': sort_direction == 'desc' ? 'descending' : 'ascending' }
  end

  # Add the params for the button_to get request
  def set_params(field, dir)
    button_to_params = {}

    params['q']&.each do |k, v|
      next if k == 's' || v.blank?

      button_to_params["q[#{k}]"] = v.to_s
    end

    button_to_params['q[s]'] = "#{field} #{dir}"
    button_to_params
  end
end
