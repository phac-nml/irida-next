# frozen_string_literal: true

module Attachments
  # Service used to Create Attachments
  class CreateService < BaseService
    attr_accessor :attachable, :attachments

    def initialize(user = nil, attachable = nil, params = {})
      super(user, params)

      @attachable = attachable
      @attachments = []

      return unless params.key?(:files)

      params[:files].each do |file|
        @attachments << Attachment.new(attachable:, file:) if file.present?
      end
    end

    def execute
      authorize! @attachable.project, to: :update_sample? if @attachable.instance_of?(Sample)

      @attachments.each(&:save)
      @attachments
    end
  end
end
