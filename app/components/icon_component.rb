# frozen_string_literal: true

class IconComponent < ViewComponent::Base
  include ViewHelper

  def initialize(name:)
    @source = heroicon_source(name)
  end
end
