# frozen_string_literal: true

module Namespaces
  # Service used to Create NamespaceGroupLinks
  class GroupShareService < BaseService
    NamespaceGroupShareError = Class.new(StandardError)
    attr_accessor :group_id, :namespace, :max_group_access_role

    def initialize(user, group_id, namespace, max_group_access_role)
      super(user, namespace)
      @group_id = group_id
      @namespace = namespace
      @max_group_access_role = max_group_access_role
    end

    def execute
      authorize! namespace, to: :share_namespace_with_group?

      group = Group.find_by(id: group_id)

      if group.nil?
        raise NamespaceGroupShareError, I18n.t('services.groups.share.group_not_found',
                                               group_id:)
      end

      namespace_group_link = NamespaceGroupLink.new(group:, namespace:,
                                                    group_access_level: max_group_access_role)

      namespace_group_link.save

      namespace_group_link
    rescue Namespaces::GroupShareService::NamespaceGroupShareError => e
      @namespace.errors.add(:base, e.message)
      false
    end
  end
end
