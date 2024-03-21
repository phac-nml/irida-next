# frozen_string_literal: true

# Concern for models that need a user type
module HasUserType
  extend ActiveSupport::Concern

  USER_TYPES = {
    human: 0,
    group_bot: 1,
    project_bot: 2
  }.with_indifferent_access.freeze

  BOT_USER_TYPES = %w[
    group_bot
    project_bot
  ].freeze

  included do
    scope :bots, -> { where(user_type: BOT_USER_TYPES) }
    scope :without_bots, -> { where(user_type: USER_TYPES.keys - BOT_USER_TYPES) }
    scope :human_users, -> { where(user_type: %i[human]) }
    scope :bots_for_puid, lambda { |puid = nil|
                            where('email LIKE ?', "%#{puid.downcase}%")
                          }

    validates :user_type, presence: true
  end

  def bot?
    BOT_USER_TYPES.include?(user_type)
  end
end
