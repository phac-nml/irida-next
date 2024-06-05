# frozen_string_literal: true

# thread-isolated attributes class
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :token
end
