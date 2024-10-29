# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test cases for the Classify functionality
  class ClassifyTest < Minitest::Test
    def test_color
      assert_generated_class('text-slate-900 dark:text-slate-100', { color: :default })
      assert_generated_class('text-white dark:text-slate-100', { color: :primary })
      assert_generated_class('text-slate-300 dark:text-slate-700', { color: :muted })
    end

    def test_background
      assert_generated_class('bg-white dark:bg-slate-800', { bg: :default })
      assert_generated_class('bg-primary-700 dark:bg-primary-600', { bg: :primary })
    end

    private

    def assert_generated_class(generated, input)
      assert_equal generated, Pathogen::Classify.call(**input)[:class]
    end
  end
end
