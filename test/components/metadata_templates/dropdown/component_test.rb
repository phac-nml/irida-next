# frozen_string_literal: true

require 'test_helper'

module MetadataTemplates
  module Dropdown
    class ComponentTest < ViewComponent::TestCase
      setup do
        @group = groups(:group_one)
        @metadata_template = metadata_templates(:valid_group_metadata_template)
        @pagy = Pagy::Offset.new(count: 10, page: 1, limit: 10)
      end

      test 'renders metadata template turbo frame with lazy loading and spinner' do
        url = Rails.application.routes.url_helpers.list_group_metadata_templates_url(
          @group,
          metadata_template: @metadata_template[:id],
          limit: @pagy&.limit,
          page: @pagy&.page
        )

        render_inline MetadataTemplates::DropdownComponent.new(url: url)

        assert_selector "turbo-frame#metadata-template-dd-menu[src='#{url}'][loading='lazy'][refresh='morph']",
                        visible: :all
        assert_text I18n.t('shared.samples.metadata_templates.loading')
      end
    end
  end
end
