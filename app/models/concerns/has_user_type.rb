# frozen_string_literal: true

# Concern for models that need a user type
module HasUserType
  extend ActiveSupport::Concern

  USER_TYPES = {
    human: 0,
    project_bot: 1
  }.with_indifferent_access.freeze

  BOT_USER_TYPES = %w[
    project_bot
  ].freeze

  included do
    attribute :user_type, :integer, default: -> { user_types[:human] }
    enum user_type: USER_TYPES

    scope :bots, -> { where(user_type: BOT_USER_TYPES) }
    scope :without_bots, -> { where(user_type: USER_TYPES.keys - BOT_USER_TYPES) }
    scope :human_users, -> { where(user_type: %i[human]) }

    validates :user_type, presence: true
  end

  def bot?
    BOT_USER_TYPES.include?(user_type)
  end
end
