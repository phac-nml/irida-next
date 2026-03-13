# frozen_string_literal: true

module PersonalAccessTokens
  # Component for rendering an personal access tokens information
  class InformationComponent < Component
    attr_accessor :current_user

    def initialize(current_user:)
      @current_user = current_user
    end
  end
end
