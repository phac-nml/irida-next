# frozen_string_literal: true

module Namespaces
  # Service used to Destroy NamespaceGroupLinks
  class GroupUnShareService < BaseService

    attr_accessor :group_id, :namespace, :max_group_access_role

    def initialize(user, group_id, namespace)
      super(user, namespace)
      @group_id = group_id
      @namespace = namespace
    end

    def execute

      # authorize! namespace, to: :unshare_namespace_with_group?

      namespace_group_link = NamespaceGroupLink.find_by(group_id:, namespace:)

      namespace_group_link.destroy

      namespace_group_link
  end
end
