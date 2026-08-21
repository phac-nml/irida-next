# frozen_string_literal: true

# View helper to display either if they member is a direct member or a link to the group they are inherited from
module MembersHelper
  def membership_source(namespace, member)
    if member.namespace_id == namespace.id
      { label: I18n.t('activerecord.models.member.direct') }
    else
      { inherited_namespace_path: resolved_group_url(member.namespace),
        label: member.namespace.name }
    end
  end

  def namespace_group_link_source(namespace, namespace_group_link)
    if namespace_group_link.namespace == namespace
      { label: I18n.t('activerecord.models.namespace_group_link.direct') }
    else
      { inherited_namespace_path: resolved_group_url(namespace_group_link.namespace),
        label: namespace_group_link.namespace.name }
    end
  end

  private

  def resolved_group_url(namespace)
    if respond_to?(:helpers) && helpers.respond_to?(:group_url)
      helpers.group_url(namespace)
    else
      group_url(namespace)
    end
  end
end
