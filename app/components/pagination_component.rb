# frozen_string_literal: true

# Pagnation component using pagy gem
class PaginationComponent < ViewComponent::Base
  attr_reader :prev_url, :next_url, :info

  def initialize(info:, prev_url: nil, next_url: nil)
    @info = info
    @prev_url = prev_url
    @next_url = next_url
  end
end
