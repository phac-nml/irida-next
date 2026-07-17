# frozen_string_literal: true

require 'test_helper'

module Viral
  module Pagy
    class LimitComponentTest < ViewComponent::TestCase
      test 'preserves nested search and sort query params as hidden fields' do
        query = 'q%5Bs%5D=puid+asc&q%5Bpuid_or_file_blob_filename_cont%5D=report'
        with_request_url "/-/groups/group-1/-/attachments?#{query}" do
          render_inline Viral::Pagy::LimitComponent.new(pagy_for(count: 25), item: 'items')

          assert_selector '#limit-component-form input[type="hidden"][name="q[s]"][value="puid asc"]',
                          visible: :hidden
          assert_selector(
            '#limit-component-form input[type="hidden"][name="q[puid_or_file_blob_filename_cont]"][value="report"]',
            visible: :hidden
          )
        end
      end

      test 'preserves explicit pagination params as hidden fields' do
        with_request_url '/workflow_executions/1' do
          render_inline Viral::Pagy::LimitComponent.new(
            pagy_for(count: 2),
            item: 'items',
            params: { tab: 'files' }
          )

          assert_selector '#limit-component-form input[type="hidden"][name="tab"][value="files"]',
                          visible: :hidden
        end
      end

      test 'does not include limit as a hidden field' do
        with_request_url '/-/groups/group-1/-/attachments?limit=20&q%5Bs%5D=puid+asc' do
          render_inline Viral::Pagy::LimitComponent.new(pagy_for(count: 25), item: 'items')

          assert_no_selector '#limit-component-form input[type="hidden"][name="limit"]', visible: :hidden
          assert_selector '#limit-component-form input[type="hidden"][name="q[s]"][value="puid asc"]',
                          visible: :hidden
        end
      end

      private

      def pagy_for(count:)
        ::Pagy::Offset.new(
          count:,
          page: 1,
          limit: 20,
          request: ::Pagy::Request.new(
            request: { base_url: 'localhost:3000', path: '/', params: {} }
          )
        )
      end
    end
  end
end
