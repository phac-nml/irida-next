# frozen_string_literal: true

module GroupLinks
  # Service used to update NamespaceGroupLinks
  class GroupLinkUpdateService < BaseService
    attr_accessor :namespace_group_link

    def initialize(user, namespace_group_link, params)
      super(user, params)
      @namespace_group_link = namespace_group_link
    end

    def execute
      authorize! @namespace_group_link.namespace, to: :update_namespace_with_group_link?

      updated = @namespace_group_link.update(params)

      if updated
        namespace_group_link.create_activity key: 'namespace_group_link.update',
                                             owner: current_user
      end

      updated
    end
  end
end
