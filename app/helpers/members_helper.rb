# frozen_string_literal: true

# Append classes to the class list ensure only unique classes are present
module MembersHelper
  def membership_source(namespace, member)
    if member.namespace_id == namespace.id
      { label: I18n.t('activerecord.models.member.direct') }
    else
      { inherited_namespace_path: group_url(member.namespace),
        label: member.namespace.name }
    end
  end
end
