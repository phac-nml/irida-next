# frozen_string_literal: true

# A simple job that waits for a specified amount of time. Used for testing purposes.
class WaitJob < ApplicationJob
  queue_as :default
  queue_with_priority 10

  def perform(wait_time)
    sleep(wait_time)
  end
end
