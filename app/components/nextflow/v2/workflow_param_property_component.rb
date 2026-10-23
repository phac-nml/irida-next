# frozen_string_literal: true

module Nextflow
  module V2
    # Render a single workflow parameter property input shared across nextflow form versions.
    class WorkflowParamPropertyComponent < Component
      include NextflowHelper

      attr_reader :fields, :name, :property, :instance, :namespace_id, :namespace_type

      def initialize(fields:, name:, property:, instance:, namespace_id:, namespace_type:) # rubocop:disable Metrics/ParameterLists
        @fields = fields
        @name = name
        @property = property
        @instance = instance
        @namespace_id = namespace_id
        @namespace_type = namespace_type

        setup_ids(@name)
      end

      private

      def setup_ids(name)
        @help_text_id = fields.field_id(name, 'help')
        @legend_id = fields.field_id(name, 'legend')
        @prefix_id = fields.field_id(name, 'prefix')
        @error_id = fields.field_id(name, 'error')
      end

      # The previously selected file when editing, so the stored value isn't dropped on save.
      def selected_attachment
        return @selected_attachment if defined?(@selected_attachment)

        global_id = instance.present? ? instance['workflow_params'][name.to_s] : nil
        @selected_attachment = global_id.present? ? GlobalID::Locator.locate(global_id, only: Attachment) : nil
      rescue ActiveRecord::RecordNotFound
        @selected_attachment = nil
      end

      # Matches the asterisk indicator PathogenFormBuilder#label renders for data-required fields,
      # for use on legends which aren't passed through PathogenFormBuilder#label. Legends name the
      # file selector link and radio group, which can't carry aria-required, so the required state
      # is also announced as visually hidden text.
      def required_indicator
        tag.span(data: { required_indicator: true }) do
          safe_join([
                      tag.abbr(
                        t('pathogen.label.required_indicator'),
                        class: 'req',
                        title: t('pathogen.label.title'),
                        aria: { hidden: true }
                      ),
                      tag.span(t('components.nextflow.required'), class: 'sr-only')
                    ], ' ')
        end
      end
    end
  end
end
