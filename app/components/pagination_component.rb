# frozen_string_literal: true

# Pagnation component using pagy gem
class PaginationComponent < ViewComponent::Base
  attr_reader :prev_url, :next_url, :info

  def initialize(info:, prev_url: nil, next_url: nil, **link_arguments)
    @info = info
    @prev_url = prev_url
    @next_url = next_url
    @link_arguments = link_arguments
  end

  def link_arguments
    if @link_arguments.empty?
      { data: {
        turbo_stream: 'true'
      } }
    else
      puts @link_arguments
      @link_arguments
    end
  end
end
