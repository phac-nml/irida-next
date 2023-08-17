# frozen_string_literal: true

module Namespaces
  # Service used to Destroy NamespaceGroupLinks
  class GroupUnshareService < BaseService
    attr_accessor :namespace_group_link

    def initialize(user, namespace_group_link, params = {})
      super(user, params)
      @namespace_group_link = namespace_group_link
    end

    def execute
      return if namespace_group_link.nil?

      authorize! namespace_group_link.namespace, to: :unlink_namespace_with_group?

      namespace_group_link.destroy
    end
  end
end
