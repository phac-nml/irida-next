# frozen_string_literal: true

# Class to make current user available to models
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
