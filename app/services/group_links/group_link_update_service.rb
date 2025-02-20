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

      create_activities if updated

      updated
    end

    private

    def create_activities # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      namespace_key = if namespace_group_link.namespace.group_namespace?
                        'group'
                      else
                        'namespaces_project_namespace'
                      end

      namespace_group_link.namespace.create_activity key: "#{namespace_key}.namespace_group_link.update",
                                                     owner: current_user,
                                                     parameters: {
                                                       group_name: namespace_group_link.group.name,
                                                       group_puid: namespace_group_link.group.puid,
                                                       namespace_name: namespace_group_link.namespace.name,
                                                       namespace_puid: namespace_group_link.namespace.puid,
                                                       namespace_type: namespace_group_link.namespace.type.downcase,
                                                       action: 'group_link_update'
                                                     }

      namespace_group_link.group.create_activity key: 'group.namespace_group_link.updated',
                                                 owner: current_user,
                                                 parameters: {
                                                   group_name: namespace_group_link.group.name,
                                                   group_puid: namespace_group_link.group.puid,
                                                   namespace_name: namespace_group_link.namespace.name,
                                                   namespace_puid: namespace_group_link.namespace.puid,
                                                   namespace_type: namespace_group_link.namespace.type.downcase,
                                                   action: 'group_link_updated'
                                                 }
    end
  end
end
