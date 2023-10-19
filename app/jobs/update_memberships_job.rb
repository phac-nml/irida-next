# frozen_string_literal: true

# Updates memberships after a group or project transfer.
class UpdateMembershipsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Do something later
    puts 'HELLO'
  end
end
