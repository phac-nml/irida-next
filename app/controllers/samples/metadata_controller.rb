# frozen_string_literal: true

module Samples
  # controller for sample metadata
  class MetadataController < ApplicationController # rubocop:disable Metrics/ClassLength
    respond_to :turbo_stream

    before_action :sample
    before_action :project
    before_action :field

    def update
      authorize! @project, to: :update_sample?

      value = params[:value]
      cell_id = params[:cell_id]

      if @sample.field?(@field)
        update_field_value(@sample.metadata[@field], value, cell_id)
      else
        create_metadata_field(@field, value, cell_id)
      end
    end

    # Param received as:
    # params: {sample: {create_fields: {key1: value1, key2: value2, ...}}}
    def bulk_create
      authorize! @project, to: :update_sample?
      @allowed_to = { update_sample: true }
      create_metadata_fields =
        ::Samples::Metadata::Fields::CreateService.new(@project, @sample, current_user,
                                                       create_field_params['create_fields']).execute

      if @sample.errors.any?
        render status: :unprocessable_content, locals: { type: 'error', message: error_message(@sample) }
      else
        @messages = bulk_create_messages(create_metadata_fields[:added_keys], create_metadata_fields[:existing_keys])
        render status: create_metadata_fields[:existing_keys].any? ? :multi_status : :ok
      end
    end

    # Param is received as:
    # params: {sample: {update_field: {key: {old_key: new_key}, value: {old_value: new_value}}}
    # Fields that have not been changed will have equal old and new
    def bulk_update # rubocop:disable Metrics/AbcSize
      authorize! @project, to: :update_sample?
      @allowed_to = { update_sample: true }
      ::Samples::Metadata::Fields::UpdateService.new(@project, @sample, current_user,
                                                     update_field_params).execute

      if @sample.errors.any?
        render status: :unprocessable_content,
               locals: { key: update_field_params['update_field']['key'].keys[0],
                         value: update_field_params['update_field']['value'].keys[0] }
      else
        render status: :ok, locals: { type: :success,
                                      message: t('projects.samples.metadata.fields.update.success') }
      end
    end

    private

    def sample
      @sample = Sample.includes(:project).find_by(id: params[:sample_id]) || not_found
    end

    def project
      @project = @sample.project
    end

    def field
      @field = params[:id]
    end

    def create_field_params
      params.expect(sample: [{ create_fields: {} }])
    end

    def update_field_params
      params.expect(sample: [{ update_field: { key: {}, value: {} } }])
    end

    def bulk_create_messages(added_keys, existing_keys)
      [
        bulk_create_success_message(added_keys),
        bulk_create_existing_message(existing_keys)
      ].compact
    end

    def bulk_create_success_message(keys)
      message = if keys.one?
                  t(
                    'projects.samples.metadata.fields.create.single_success',
                    key: keys.first
                  )
                else
                  t(
                    'projects.samples.metadata.fields.create.multi_success',
                    keys: keys.join(', ')
                  )
                end

      { type: 'success', message: message }
    end

    def bulk_create_existing_message(keys)
      return if keys.empty?

      message = if keys.one?
                  t(
                    'projects.samples.metadata.fields.create.single_key_exists',
                    key: keys.first
                  )
                else
                  t(
                    'projects.samples.metadata.fields.create.multi_keys_exists',
                    keys: keys.join(', ')
                  )
                end

      { type: 'error', message: message }
    end

    def create_metadata_field(field, value, cell_id)
      create_params = { field => value }
      ::Samples::Metadata::Fields::CreateService.new(@project, @sample, current_user, create_params).execute

      if @sample.errors.any?
        render_update_error(cell_id)
      else
        render_update_success(cell_id)
      end
    end

    def update_field_value(original_value, new_value, cell_id)
      perform_field_update(original_value, new_value)

      if @sample.errors.any?
        render_update_error(cell_id)
      else
        render_update_success(cell_id)
      end
    end

    def perform_field_update(original_value, new_value)
      ::Samples::Metadata::Fields::UpdateService.new(
        @project,
        @sample,
        current_user,
        build_update_params(original_value, new_value)
      ).execute
    end

    def build_update_params(original_value, new_value)
      {
        'update_field' => {
          'key' => { @field => @field },
          'value' => { original_value => new_value }
        }
      }
    end

    def render_update_error(cell_id)
      render status: :unprocessable_content,
             turbo_stream: [
               turbo_stream.update(
                 cell_id, @sample.metadata[@field]
               ),
               turbo_stream.append(
                 'flashes',
                 partial: 'shared/flash',
                 locals: { type: 'error',
                           message: error_message(@sample) }
               )
             ]
    end

    def render_update_success(cell_id)
      # When the timestamp is rendered to the form, it only renders down to the second, this was causing timing
      # issues for selecting current samples.  To fix this, we are adding a second to the timestamp so that the
      # timestamp is always greater than the current time.
      @timestamp = @sample.updated_at + 1.second
      render turbo_stream: [
        turbo_stream.replace(
          cell_id, Samples::EditableCell.new(field: @field, sample: @sample, data: { refocus: 'true' })
        ),
        turbo_stream.append(
          'flashes',
          partial: 'shared/flash',
          locals: { type: 'success',
                    message: t('samples.editable_cell.update_success') }
        ),
        turbo_stream.replace('timestamp', partial: 'shared/samples/timestamp_input')
      ]
    end
  end
end
