# frozen_string_literal: true

require 'test_helper'

class MetadataTemplateTest < ActiveSupport::TestCase
  setup do
    @namespace = namespaces_user_namespaces(:john_doe_namespace)
    @user = users(:john_doe)
    @valid_metadata_template = metadata_templates(:valid_metadata_template)
    @invalid_metadata_template = metadata_templates(:invalid_metadata_template)
  end

  test 'valid metadata template' do
    assert @valid_metadata_template.valid?
    assert_not_nil @valid_metadata_template.name
  end

  test 'invalid without name' do
    @valid_metadata_template.name = nil
    assert_not @valid_metadata_template.valid?
    assert_not_nil @valid_metadata_template.errors[:name]
  end

  test 'invalid with duplicate name in same namespace' do
    duplicate = @valid_metadata_template.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], 'has already been taken'
  end

  test 'valid with same name in different namespace' do
    duplicate = @valid_metadata_template.dup
    duplicate.namespace = namespaces_user_namespaces(:jane_doe_namespace)
    assert duplicate.valid?
  end

  test 'description length validation' do
    @valid_metadata_template.description = 'a' * 1001
    assert_not @valid_metadata_template.valid?
  end

  # Association Tests
  test 'belongs to namespace' do
    assert_respond_to @valid_metadata_template, :namespace
    assert_instance_of Namespaces::ProjectNamespace, @valid_metadata_template.namespace
  end

  test 'belongs to created_by user' do
    assert_respond_to @valid_metadata_template, :created_by
    assert_instance_of User, @valid_metadata_template.created_by
  end

  test 'has many metadata fields' do
    assert_respond_to @valid_metadata_template, :fields
    assert_kind_of Array, @valid_metadata_template.fields
  end

  # Soft Delete Tests
  test 'soft deletes record' do
    @valid_metadata_template.destroy
    assert_not_nil @valid_metadata_template.deleted_at
    assert_not MetadataTemplate.find_by(id: @valid_metadata_template.id)
    assert MetadataTemplate.with_deleted.find_by(id: @valid_metadata_template.id)
  end

  # Activity Tracking Tests
  # test 'tracks activity on create' do
  #   template = MetadataTemplate.new(
  #     name: 'Activity Test',
  #     namespace: @namespace,
  #     created_by: @user
  #   )
  #   assert_difference 'Activity.count' do
  #     template.save
  #   end
  # end

  test 'tracks history changes' do
    @valid_metadata_template.create_logidze_snapshot!

    assert_equal 1, @valid_metadata_template.log_data.version
    assert_equal 1, @valid_metadata_template.log_data.size

    assert_changes -> { @valid_metadata_template.name }, to: 'Updated Name' do
      @valid_metadata_template.update(name: 'Updated Name')
    end

    @valid_metadata_template.create_logidze_snapshot!

    assert_equal 2, @valid_metadata_template.log_data.version
    assert_equal 2, @valid_metadata_template.log_data.size
  end
end
