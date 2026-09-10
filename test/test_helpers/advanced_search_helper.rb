# frozen_string_literal: true

# Shared helpers for exercising the attachments advanced search at the request level.
module AdvancedSearchHelper
  # Builds the nested `q[groups_attributes]` params the attachments advanced search form
  # submits. `groups` is an array of groups, where each group is an array of condition
  # hashes such as { field:, operator:, value: } (omit `value` for existence operators,
  # or pass an array for `in`/`not_in`).
  def advanced_search_params(groups)
    groups_attributes = groups.each_with_index.to_h do |conditions, group_index|
      conditions_attributes = conditions.each_with_index.to_h do |condition, condition_index|
        [condition_index.to_s, condition]
      end
      [group_index.to_s, { conditions_attributes: }]
    end

    { q: { groups_attributes: } }
  end
end
