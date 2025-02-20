# frozen_string_literal: true

module GroupLinks
  # Service used to Destroy NamespaceGroupLinks
  class GroupUnlinkService < BaseService
    attr_accessor :namespace_group_link

    def initialize(user, namespace_group_link, params = {})
      super(user, params)
      @namespace_group_link = namespace_group_link
    end

    def execute
      return if namespace_group_link.nil?

      authorize! namespace_group_link.namespace, to: :unlink_namespace_with_group?

      namespace_group_link.destroy

      return unless namespace_group_link.deleted?

      create_activities
    end

    private

    def create_activities # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      namespace_key = if namespace_group_link.namespace.group_namespace?
                        'group'
                      else
                        'namespaces_project_namespace'
                      end

      namespace_group_link.namespace.create_activity key: "#{namespace_key}.namespace_group_link.destroy",
                                                     owner: current_user,
                                                     parameters: {
                                                       group_name: namespace_group_link.group.name,
                                                       group_puid: namespace_group_link.group.puid,
                                                       namespace_name: namespace_group_link.namespace.name,
                                                       namespace_puid: namespace_group_link.namespace.puid,
                                                       namespace_type: namespace_group_link.namespace.type.downcase,
                                                       action: 'group_link_destroy'
                                                     }

      namespace_group_link.group.create_activity key: 'group.namespace_group_link.destroyed',
                                                 owner: current_user,
                                                 parameters: {
                                                   group_name: namespace_group_link.group.name,
                                                   group_puid: namespace_group_link.group.puid,
                                                   namespace_name: namespace_group_link.namespace.name,
                                                   namespace_puid: namespace_group_link.namespace.puid,
                                                   namespace_type: namespace_group_link.namespace.type.downcase,
                                                   action: 'group_link_destroyed'
                                                 }
    end
  end
end
