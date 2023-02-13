# frozen_string_literal: true

module Constraints
  # Used to constrain urls that are for users
  class UserUrlConstrainer
    def matches?(request)
      full_path = request.params[:username]

      return false unless NamespacePathValidator.valid_path?(full_path)

      Namespaces::UserNamespace.find_by_full_path(full_path).present? # rubocop:disable Rails/DynamicFindBy
    end
  end
end
