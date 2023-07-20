# frozen_string_literal: true

module Groups
  # Service used to share a namespace with a group
  class ShareService < BaseService
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
    rescue Groups::ShareService::NamespaceGroupShareError => e
      @namespace.errors.add(:base, e.message)
      false
    end
  end
end
