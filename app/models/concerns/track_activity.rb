# frozen_string_literal: true

# Concern to make a Model activity trackable
module TrackActivity
  extend ActiveSupport::Concern

  included do
    include PublicActivity::Model
    tracked owner: proc{ |controller, _model| controller.current_user }
  end
end
