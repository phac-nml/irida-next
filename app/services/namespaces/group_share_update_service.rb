# frozen_string_literal: true

module Namespaces
  # Service used to update NamespaceGroupLinks
  class GroupShareUpdateService < BaseService
    attr_accessor :namespace_group_link

    def initialize(user, namespace_group_link, params)
      super(user, params)
      @namespace_group_link = namespace_group_link
    end

    def execute
      authorize! @namespace_group_link.namespace, to: :update_namespace_with_group_share?

      @namespace_group_link.update(params)
    end
  end
end
