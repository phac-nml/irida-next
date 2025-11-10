# frozen_string_literal: true

# Pagnation component using pagy gem
class PaginationComponent < Component
  attr_reader :prev_url, :next_url, :info, :info_id

  def initialize(info:, prev_url: nil, next_url: nil, autofocus_link: false, **link_arguments)
    @info = info
    @prev_url = prev_url
    @next_url = next_url
    @autofocus_link = autofocus_link
    @link_arguments = link_arguments
    @info_id = "pagination-info-#{SecureRandom.uuid}"
  end

  def link_arguments
    if @link_arguments.empty?
      { data: {
        turbo_stream: 'true'
      } }
    else
      @link_arguments
    end
  end
end
