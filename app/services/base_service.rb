# frozen_string_literal: true

# Base root class for service related classes
class BaseService
  attr_accessor :current_user, :params

  def initialize(user = nil, params = {})
    @current_user = user
    @params = params.dup
  end
end
