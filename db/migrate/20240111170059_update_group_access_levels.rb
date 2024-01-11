# frozen_string_literal: true

# migration to update the group access levels for namespace group links as a new role `Uploader` was added
class UpdateGroupAccessLevels < ActiveRecord::Migration[7.1]
  def change
    namespace_group_links = NamespaceGroupLink.where(group_access_level: [Member::AccessLevel::ANALYST - 10,
                                                                          Member::AccessLevel::MAINTAINER - 10,
                                                                          Member::AccessLevel::OWNER - 10])

    namespace_group_links.each do |namespace_group_link|
      namespace_group_link.update(group_access_level: namespace_group_link.group_access_level += 10)
    end
  end
end
