# frozen_string_literal: true

module Constraints
  # Used to constrain urls that are for groups
  class GroupUrlConstrainer
    def matches?(request)
      full_path = request.params[:group_id] || request.params[:id]

      return false unless NamespacePathValidator.valid_path?(full_path)

      Group.find_by_full_path(full_path).present? # rubocop:disable Rails/DynamicFindBy
    end
  end
end
