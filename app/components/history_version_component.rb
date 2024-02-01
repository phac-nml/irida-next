# frozen_string_literal: true

# UI History Version Display Component
class HistoryVersionComponent < Component
  include JsonHelper

  attr_accessor :log_data

  def initialize(
    log_data: nil,
    **system_arguments
  )
    @log_data = log_data
    @system_arguments = system_arguments
  end
end
