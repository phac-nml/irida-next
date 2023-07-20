# frozen_string_literal: true

# Ransack Sorting Helper
module SortingHelper
  def active_sort(ransack_obj, field, dir)
    return false unless ransack_obj.sorts.detect { |s| s && s.name == field && s.dir == dir }

    true
  end
end
