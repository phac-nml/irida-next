# frozen_string_literal: true

module Pathogen
  module Pagination
    module ComponentTestHelper
      def mock_pagy(count: 100, page: 1, items: 10, pages: 10, **overrides)
        pagy = instance_double(
          'Pagy',
          count: count,
          page: page,
          items: items,
          pages: pages,
          vars: { items: items },
          from: 1,
          to: [items, count].min,
          prev: page > 1 ? page - 1 : nil,
          next: page < pages ? page + 1 : nil,
          series: (1..pages).to_a,
          **overrides
        )
        
        allow(pagy).to receive(:is_a?).with(Pagy).and_return(true)
        pagy
      end

      def mock_request
        instance_double(
          'ActionDispatch::Request',
          path: '/test',
          query_parameters: {},
          params: {}
        )
      end
    end
  end
end
