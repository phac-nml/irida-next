# frozen_string_literal: true

# migration to update the access levels for members and namespace group links as a new role `Uploader` was added
class UpdateMemberAccessLevels < ActiveRecord::Migration[7.1]
  def change
    old_access_levels = { analyst: 20, maintainer: 30, owner: 40 }

    members = Member.where(access_level: [old_access_levels[:analyst],
                                          old_access_levels[:maintainer],
                                          old_access_levels[:owner]])

    members.each do |member|
      member.update(access_level: member.access_level += 10)
    end

    namespace_group_links = NamespaceGroupLink.where(group_access_level: [old_access_levels[:analyst],
                                                                          old_access_levels[:maintainer],
                                                                          old_access_levels[:owner]])

    namespace_group_links.each do |namespace_group_link|
      namespace_group_link.update(group_access_level: namespace_group_link.group_access_level += 10)
    end
  end
end
