# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test cases for the Classify functionality
  class ClassifyTest < Minitest::Test
    def test_margins
      assert_generated_class('m-4',   { m: 4 })
      assert_generated_class('mx-4',  { mx: 4 })
      assert_generated_class('my-4',  { my: 4 })
      assert_generated_class('mt-4',  { mt: 4 })
      assert_generated_class('ml-4',  { ml: 4 })
      assert_generated_class('mb-4',  { mb: 4 })
      assert_generated_class('mr-4',  { mr: 4 })
    end

    private

    def assert_generated_class(generated, input)
      assert_equal generated, Pathogen::Classify.call(**input)[:class]
    end
  end
end
