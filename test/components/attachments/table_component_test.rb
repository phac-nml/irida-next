# frozen_string_literal: true

require 'test_helper'

module Attachments
  class TableComponentTest < ViewComponent::TestCase
    test 'adds turbo_action replace to sort links when sort_replaces_history is true' do
      render_table_component(sort_replaces_history: true)

      assert_selector 'table thead a[data-turbo-action="replace"]', count: 6
    end

    test 'does not add turbo_action replace to sort links when sort_replaces_history is false' do
      render_table_component(sort_replaces_history: false)

      assert_no_selector 'table thead a[data-turbo-action="replace"]'
    end

    test 'preserves pagination params as hidden limit form fields' do
      render_table_component(sort_replaces_history: false, pagination_params: { tab: 'files' })

      assert_selector '#limit-component-form input[type="hidden"][name="tab"][value="files"]', visible: :hidden
    end

    test 'does not add pagination params by default' do
      render_table_component(sort_replaces_history: false)

      assert_no_selector '#limit-component-form input[type="hidden"][name="tab"]', visible: :hidden
    end

    private

    def render_table_component(sort_replaces_history:, pagination_params: {})
      with_request_url '/-/groups/group-1/-/attachments' do
        attachments = Attachment.where(id: attachments(:attachment1).id)
        pagy = pagy_for(attachments)
        q = Attachment.ransack({ s: 'puid asc' })
        render_inline Attachments::TableComponent.new(
          attachments,
          pagy,
          q,
          groups(:group_one),
          true,
          true,
          sort_replaces_history:,
          pagination_params:, row_actions: {}
        )
      end
    end

    def pagy_for(attachments)
      Pagy::Offset.new(count: attachments.count, page: 1, limit: 20,
                       request: Pagy::Request.new(
                         request: { base_url: 'localhost:3000', path: '/', params: {} }
                       ))
    end
  end
end
