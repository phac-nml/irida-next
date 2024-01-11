# frozen_string_literal: true

# migration to update the access levels for members as a new role `Uploader` was added
class UpdateMemberAccessLevels < ActiveRecord::Migration[7.1]
  def change
    members = Member.where(access_level: [Member::AccessLevel::ANALYST - 10, Member::AccessLevel::MAINTAINER - 10,
                                          Member::AccessLevel::OWNER - 10])

    members.each do |member|
      member.update(access_level: member.access_level += 10)
    end
  end
end
