# frozen_string_literal: true

require 'test_helper'

class IridaSchemaTest < ActiveSupport::TestCase
  test 'schema is up to date' do
    current_schema = IridaSchema.to_definition
    generated_schema = Rails.root.join('app/graphql/schema.graphql').read

    assert_equal current_schema, generated_schema,
                 'Update the generated schema with `bin/rails graphql:dump_schema`'
  end

  test 'has the base mutation' do
    assert_equal Types::MutationType, IridaSchema.mutation
  end

  test 'has the base query' do
    assert_equal Types::QueryType, IridaSchema.query
  end

  test '#id_from_object returns a global id' do
    assert_instance_of GlobalID, IridaSchema.id_from_object(groups(:group_one))
  end

  test '#object_from_id returns the correct record' do
    assert_equal groups(:group_one), IridaSchema.object_from_id(groups(:group_one).to_global_id.to_s)
  end

  test '#object_from_id returns the correct record, of the expected type' do
    gid_string = groups(:group_one).to_global_id.to_s

    assert_equal groups(:group_one), IridaSchema.object_from_id(gid_string, expected_type: Group)
  end

  test '#object_from_id fails if the type does not match' do
    assert_raises GraphQL::CoercionError do
      IridaSchema.object_from_id(groups(:group_one).to_global_id.to_s, expected_type: Project)
    end
  end

  test '#parse_gid parses the gid' do
    global_id = 'gid://irida/Group/12345'
    gid = IridaSchema.parse_gid(global_id)

    assert_equal '12345', gid.model_id
    assert_equal 'Group', gid.model_name
  end

  test '#parse_gid when gid is malformed raises an error' do
    global_id = 'malformed://irida/Group/12345'

    assert_raises GraphQL::CoercionError do
      IridaSchema.parse_gid(global_id)
    end
  end

  test '#parse_gid when gid is wrongapp raises an error' do
    global_id = 'gid://wrongapp/Sample/asdfqwerty'

    assert_raises GraphQL::CoercionError do
      IridaSchema.parse_gid(global_id)
    end
  end

  test '#parse_gid when using expected_type accepts a single type' do
    global_id = 'gid://irida/Group/12345'
    gid = IridaSchema.parse_gid(global_id, expected_type: Group)

    assert_equal 'Group', gid.model_name
  end

  test '#parse_gid when using expected_type accepts an ancestor type' do
    global_id = 'gid://irida/Group/12345'
    gid = IridaSchema.parse_gid(global_id, expected_type: Namespace)

    assert_equal 'Group', gid.model_name
  end

  test '#parse_gid when using expected_type rejects an unknown type' do
    global_id = 'gid://irida/Group/12345'

    assert_raises GraphQL::CoercionError do
      IridaSchema.parse_gid(global_id, expected_type: Project)
    end
  end

  test '#parse_gid when using expected_type accepts an array of types' do
    global_id = 'gid://irida/Group/12345'
    gid = IridaSchema.parse_gid(global_id, expected_type: [Group, Project])

    assert_equal 'Group', gid.model_name
  end

  test '#parse_gid when using expected_type rejects an unknown type not present in an array of types' do
    global_id = 'gid://irida/Group/12345'

    assert_raises GraphQL::CoercionError do
      IridaSchema.parse_gid(global_id, expected_type: [User, Project])
    end
  end
end
