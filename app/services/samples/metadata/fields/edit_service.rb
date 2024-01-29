# frozen_string_literal: true

module Samples
  module Metadata
    module Fields
      # Service used to Update Samples::Metadata
      class EditService < BaseService
        SampleMetadataFieldsEditError = Class.new(StandardError)
        attr_accessor :project, :sample, :edit_fields

        def initialize(project, sample, user = nil, params = {})
          super(user, params)
          @project = project
          @sample = sample
          @key_edit = params['edit_field']['key']
          @value_edit = params['edit_field']['value']
          @metadata_update_params = {}
        end

        def execute
          authorize! @project, to: :update_sample?

          validate_edit_fields

          construct_metadata_update_params
        rescue Samples::Metadata::Fields::EditService::SampleMetadataFieldsEditError => e
          @sample.errors.add(:base, e.message)
          @metadata_update_params
        end

        private

        def validate_edit_fields
          return unless @key_edit.keys[0] == @key_edit.values[0] && @value_edit.keys[0] == @value_edit.values[0]

          raise SampleMetadataFieldsEditError, I18n.t('services.samples.metadata.edit_fields.metadata_was_not_changed')
        end

        def construct_metadata_update_params
          metadata_update_params = { metadata: {} }
          if @key_edit.keys[0] != @key_edit.values[0]
            if validate_new_key
              raise SampleMetadataFieldsEditError,
                    I18n.t('services.samples.metadata.edit_fields.key_exists', key: @key_edit.values[0])
            end

            metadata_update_params[:metadata][@key_edit.keys[0]] = ''
          end

          metadata_update_params[:metadata][@key_edit.values[0]] = @value_edit.values[0]
          metadata_update_params
        end

        def validate_new_key
          key_exists = false
          @sample.metadata.each do |k, _v|
            if k.downcase == @key_edit.values[0].downcase
              key_exists = true
              break
            end
          end
          key_exists
        end
      end
    end
  end
end
