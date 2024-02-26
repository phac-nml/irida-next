# frozen_string_literal: true

module Attachments
  # Service used to Create Attachments
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      authorize! @attachable.project, to: :update_sample? if @attachable.instance_of?(Sample)
    end
  end
end
