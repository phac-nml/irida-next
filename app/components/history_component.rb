# frozen_string_literal: true

# UI History Component
class HistoryComponent < Component
  include PathHelper

  def initialize(
    data: nil,
    type: nil,
    url: nil,
    **system_arguments
  )
    @data = data
    @type = type
    @url = url
    @system_arguments = system_arguments
  end
end
