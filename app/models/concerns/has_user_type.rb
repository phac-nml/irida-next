# frozen_string_literal: true

# Concern for models that need a user type
module HasUserType
  extend ActiveSupport::Concern

  USER_TYPES = %i[
    human
    project_bot
    group_bot
    project_automation_bot
  ].freeze

  BOT_USER_TYPES = %i[
    project_bot
    group_bot
    project_automation_bot
  ].freeze

  AUTOMATION_BOT_USER_TYPES = %i[
    project_automation_bot
  ].freeze

  included do
    attribute :user_type, :integer, default: -> { user_types[:human] }
    enum :user_type, USER_TYPES

    scope :bots, -> { where(user_type: BOT_USER_TYPES) }
    scope :without_automation_bots, -> { where(user_type: USER_TYPES - AUTOMATION_BOT_USER_TYPES) }
    scope :without_bots, -> { where(user_type: USER_TYPES - BOT_USER_TYPES) }
    scope :human_users, -> { where(user_type: %i[human]) }

    validates :user_type, presence: true
  end

  def human?
    (USER_TYPES - BOT_USER_TYPE).include?(user_type.to_sym)
  end

  def bot?
    BOT_USER_TYPES.include?(user_type.to_sym)
  end

  def automation_bot?
    AUTOMATION_BOT_USER_TYPES.include?(user_type.to_sym)
  end
end
