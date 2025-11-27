# frozen_string_literal: true

module SuppressibleCounterCache # rubocop:disable Style/Documentation
  extend ActiveSupport::Concern

  included do
    thread_mattr_accessor :suppressed_counter_caches, instance_accessor: false
    delegate :suppressed_counter_caches?, to: 'self.class'

    def saved_change_to_attribute?(attr_name, **options)
      if suppressed_counter_caches? && attr_name.to_s.end_with?('_id')
        false
      else
        super
      end
    end
  end

  module ClassMethods # rubocop:disable Style/Documentation
    # Executes +block+ preventing counter cache updates from this model.
    def suppressing_counter_caches(&)
      original = suppressed_counter_caches
      self.suppressed_counter_caches = true
      yield
    ensure
      self.suppressed_counter_caches = original
    end

    def suppressed_counter_caches?
      suppressed_counter_caches
    end
  end
end
