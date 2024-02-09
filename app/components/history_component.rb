# frozen_string_literal: true

# UI History Listing Component
class HistoryComponent < Component
  include PathHelper

  def initialize(
    data: nil,
    type: nil,
    url: nil
  )
    @data = data
    @type = type
    @url = url
  end
end
