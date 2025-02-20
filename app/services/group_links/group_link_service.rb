# frozen_string_literal: true

module GroupLinks
  # Service used to Create NamespaceGroupLinks
  class GroupLinkService < BaseService
    NamespaceGroupLinkError = Class.new(StandardError)
    attr_accessor :group_id, :namespace, :namespace_group_link

    def initialize(user, namespace, params)
      super(user, params)
      @group_id = params[:group_id]
      @namespace = namespace
      @namespace_group_link = NamespaceGroupLink.new(params.merge(namespace:))
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      unless [Group.sti_name, Namespaces::ProjectNamespace.sti_name].include?(namespace.type)
        raise NamespaceGroupLinkError, I18n.t('services.groups.share.invalid_namespace_type')
      end

      authorize! namespace, to: :link_namespace_with_group?

      if group_id == namespace.id
        raise NamespaceGroupLinkError,
              I18n.t('services.groups.share.group_self_reference', group_id:)
      end

      group = Group.find_by(id: group_id)

      raise NamespaceGroupLinkError, I18n.t('services.groups.share.group_not_found', group_id:) if group.nil?

      namespace_group_link.save

      create_activities if namespace_group_link.persisted?

      namespace_group_link
    rescue GroupLinks::GroupLinkService::NamespaceGroupLinkError => e
      @namespace_group_link.errors.add(:base, e.message)
      @namespace_group_link
    end

    private

    def create_activities # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      namespace_key = if namespace.group_namespace?
                        'group'
                      else
                        'namespaces_project_namespace'
                      end
      namespace_group_link.namespace.create_activity key: "#{namespace_key}.namespace_group_link.create",
                                                     owner: current_user,
                                                     parameters: {
                                                       group_name: namespace_group_link.group.name,
                                                       group_puid: namespace_group_link.group.puid,
                                                       namespace_name: namespace_group_link.namespace.name,
                                                       namespace_puid: namespace_group_link.namespace.puid,
                                                       namespace_type: namespace_group_link.namespace.type.downcase,
                                                       action: 'group_link_create'
                                                     }

      namespace_group_link.group.create_activity key: 'group.namespace_group_link.created',
                                                 owner: current_user,
                                                 parameters: {
                                                   group_name: namespace_group_link.group.name,
                                                   group_puid: namespace_group_link.group.puid,
                                                   namespace_name: namespace_group_link.namespace.name,
                                                   namespace_puid: namespace_group_link.namespace.puid,
                                                   namespace_type: namespace_group_link.namespace.type.downcase,
                                                   action: 'group_link_created'
                                                 }
    end
  end
end
