# frozen_string_literal: true

class ProviderIconComponent < ViewComponent::Base
  def initialize(provider:)
    @provider = provider
  end
end
