# frozen_string_literal: true

# View helper to display either if they member is a direct member or a link to the group they are inherited from
module MembersHelper
  def membership_source(namespace, member)
    if member.namespace_id == namespace.id
      { label: I18n.t('activerecord.models.member.direct') }
    else
      { inherited_namespace_path: group_url(member.namespace),
        label: member.namespace.name }
    end
  end

  def namespace_group_link_source(namespace, namespace_group_link)
    if namespace_group_link.namespace == namespace
      { label: 'Direct shared' }
    else
      { inherited_indirect_namespace_path: group_url(namespace_group_link.namespace),
        label: namespace_group_link.namespace.name }
    end
  end
end
