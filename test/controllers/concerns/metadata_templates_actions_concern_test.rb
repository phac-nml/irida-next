# frozen_string_literal: true

require 'test_helper'

class MetadataTemplateActionsConcernTest < ActionDispatch::IntegrationTest
  test 'metadata_templates_path raises NotImplementedError when not overridden' do
    controller_class = Class.new(ApplicationController) do
      include MetadataTemplateActions
    end

    assert_raises(NotImplementedError) do
      controller_class.new.send(:metadata_templates_path)
    end
  end
end
