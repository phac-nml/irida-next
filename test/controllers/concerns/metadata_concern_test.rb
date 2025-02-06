# frozen_string_literal: true

require 'test_helper'

class TestController < ApplicationController
  include Metadata
end

class MetadataConcernTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @group = groups(:group_one)
    @project = projects(:project1)
    @controller = TestController.new
  end

  test 'fields_for_namespace_or_template returns empty array when template is blank' do
    fields = @controller.fields_for_namespace_or_template(namespace: @group, template: '')
    assert_empty fields
  end

  test 'fields_for_namespace_or_template returns empty array when template is none' do
    fields = @controller.fields_for_namespace_or_template(namespace: @group, template: 'none')
    assert_empty fields
  end

  test 'fields_for_namespace_or_template returns namespace fields when template is all' do
    expected_fields = @group.metadata_fields
    fields = @controller.fields_for_namespace_or_template(namespace: @group, template: 'all')

    assert_equal expected_fields, fields
  end

  test 'fields_for_namespace_or_template returns template fields for specific template' do
    template = metadata_templates(:valid_group_metadata_template)
    fields = @controller.fields_for_namespace_or_template(namespace: @group, template: template.id)

    assert_equal template.fields, fields
  end

  test 'advanced_search_fields returns combined sample and metadata fields' do
    expected_base_fields = %w[name puid created_at updated_at attachments_updated_at]
    metadata_fields = @group.metadata_fields.map { |field| "metadata.#{field}" }
    expected_fields = expected_base_fields.concat(metadata_fields)

    @controller.advanced_search_fields(@group)
    actual_fields = @controller.instance_variable_get(:@advanced_search_fields)

    assert_equal expected_fields.sort, actual_fields.sort
  end

  test 'current_metadata_template returns none when params are empty' do
    params = { metadata_template: '' }
    result = @controller.current_metadata_template(params)

    assert_equal 'none', result
    assert_equal 'none', params[:metadata_template]
  end

  test 'current_metadata_template preserves existing template value' do
    params = { metadata_template: 'template1' }
    result = @controller.current_metadata_template(params)

    assert_equal 'template1', result
    assert_equal 'template1', params[:metadata_template]
  end

  test 'metadata_templates_for_namespace returns formatted template options' do
    template = metadata_templates(:valid_group_metadata_template)
    @controller.metadata_templates_for_namespace(namespace: @group)
    actual_templates = @controller.instance_variable_get(:@metadata_templates)

    assert_includes actual_templates, [template.name, template.id]
  end
end
