# frozen_string_literal: true

module Resolvers
  # Members Resolver
  class MembersResolver < BaseResolver
    type [[String]], null: false
    alias namespace object

    def resolve
      members = Member.joins(:user, :namespace).where(namespace: { puid: namespace.puid }).pluck(:email,
                                                                                                 :access_level)
      members.map do |email, access_level|
        [email, I18n.t("members.access_levels.level_#{access_level}")]
      end
    end
  end
end
