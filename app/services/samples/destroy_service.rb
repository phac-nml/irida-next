# frozen_string_literal: true

module Samples
  # Service used to Delete Samples
  class DestroyService < BaseService
    attr_accessor :sample

    def initialize(sample, user = nil, params = {})
      super(user, params.except(:sample, :id))
      @sample = sample
    end

    def execute
      if @sample.nil?
        nil
      elsif @sample.project.namespace.owners.find_by(id: current_user.id) ||
            current_user == @sample.project.namespace.owner
        @sample.destroy
      else
        @sample.errors.add(:base, 'You are not authorized to remove this sample from the project.')
      end
    end
  end
end
