# frozen_string_literal: true

require 'test_helper'

class MetadataTemplateTest < ActiveSupport::TestCase
  setup do
    @namespace = namespaces_user_namespaces(:john_doe_namespace)
    @user = users(:john_doe)
    @valid_metadata_template = metadata_templates(:valid_metadata_template)
    @invalid_metadata_template = metadata_templates(:invalid_metadata_template)
  end

  # Validation Tests
  test 'valid metadata template' do
    assert @valid_metadata_template.valid?
    assert_not_nil @valid_metadata_template.name
  end

  test 'invalid without name' do
    assert_not @invalid_metadata_template.valid?
    # assert_not_nil @invalid_metadata_template.errors[:name]
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
    assert_includes @valid_metadata_template.errors[:description], 'is too long'
  end

  # Association Tests
  test 'belongs to namespace' do
    assert_respond_to @valid_metadata_template, :namespace
    assert_instance_of Namespace, @valid_metadata_template.namespace
  end

  test 'belongs to created_by user' do
    assert_respond_to @valid_metadata_template, :created_by
    assert_instance_of User, @valid_metadata_template.created_by
  end

  test 'has many metadata fields' do
    assert_respond_to @valid_metadata_template, :metadata_fields
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @valid_metadata_template.metadata_fields
  end

  # Soft Delete Tests
  test 'soft deletes record' do
    @valid_metadata_template.destroy
    assert_not_nil @valid_metadata_template.deleted_at
    assert_not MetadataTemplate.find_by(id: @valid_metadata_template.id)
    assert MetadataTemplate.with_deleted.find_by(id: @valid_metadata_template.id)
  end

  # Broadcasting Tests
  test 'broadcasts refresh on save' do
    assert_broadcasts @valid_metadata_template, :refresh do
      @valid_metadata_template.save
    end
  end

  # Activity Tracking Tests
  test 'tracks activity on create' do
    template = MetadataTemplate.new(
      name: 'Activity Test',
      namespace: @namespace,
      created_by: @user
    )
    assert_difference 'Activity.count' do
      template.save
    end
  end

  # Logidze Tests
  test 'tracks history changes' do
    original_name = @valid_metadata_template.name
    assert_difference '@valid_metadata_template.log_size' do
      @valid_metadata_template.update!(name: 'Updated Name')
    end
    assert_equal original_name, @valid_metadata_template.log_data.versions.first['changes']['name']
  end
end
