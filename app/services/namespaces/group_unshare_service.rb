# frozen_string_literal: true

module Namespaces
  # Service used to Destroy NamespaceGroupLinks
  class GroupUnshareService < BaseService
    NamespaceGroupUnshareError = Class.new(StandardError)
    attr_accessor :group_id, :namespace, :max_group_access_role

    def initialize(user, group_id, namespace)
      super(user, namespace)
      @group_id = group_id
      @namespace = namespace
    end

    def execute
      authorize! namespace, to: :unshare_namespace_with_group?

      namespace_group_link = NamespaceGroupLink.find_by(group_id:, namespace:)

      raise NamespaceGroupUnshareError, 'Namespace to group link does not exist' if namespace_group_link.nil?

      namespace_group_link.destroy
    rescue Namespaces::GroupUnshareService::NamespaceGroupUnshareError => e
      @namespace.errors.add(:base, e.message)
      false
    end
  end
end
