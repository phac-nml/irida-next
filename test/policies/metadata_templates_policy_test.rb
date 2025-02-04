# frozen_string_literal: true

require 'test_helper'

class MetadataTemplatePolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @group_namespace = groups(:group_one)
    @project_namespace = namespaces_project_namespaces(:project1_namespace)
    @policy = MetadataTemplatePolicy.new(metadata_templates(:group_one_metadata_template0), user: @user)
    @details = {}
  end

  test '#destroy_metadata_template?' do
    assert @policy.apply(:destroy_metadata_template?)

    user = users(:ryan_doe)
    policy = MetadataTemplatePolicy.new(metadata_templates(:group_one_metadata_template0), user: user)

    assert_not policy.apply(:destroy_metadata_template?)

    user = users(:ryan_doe)
    policy = MetadataTemplatePolicy.new(metadata_templates(:project1_metadata_template0), user: user)

    assert_not policy.apply(:destroy_metadata_template?)
  end

  test '#update_metadata_template?' do
    assert @policy.apply(:update_metadata_template?)

    user = users(:ryan_doe)
    policy = MetadataTemplatePolicy.new(metadata_templates(:group_one_metadata_template0), user: user)

    assert_not policy.apply(:update_metadata_template?)

    user = users(:ryan_doe)
    policy = MetadataTemplatePolicy.new(metadata_templates(:project1_metadata_template0), user: user)

    assert_not policy.apply(:update_metadata_template?)
  end

  test 'scope' do
    policy = MetadataTemplatePolicy.new(user: @user)
    scoped_templates = policy.apply_scope(MetadataTemplate, type: :relation,
                                                            scope_options: { namespace: @group_namespace })

    assert_equal 22, scoped_templates.length

    scoped_templates = policy.apply_scope(MetadataTemplate, type: :relation,
                                                            scope_options: { namespace: @project_namespace })

    assert_equal 22, scoped_templates.length # 22 from group inheritance and 22 within the project

    group_namespace = groups(:group_three)
    scoped_templates = policy.apply_scope(MetadataTemplate, type: :relation,
                                                            scope_options: { namespace: group_namespace })

    assert_equal 0, scoped_templates.length
  end
end
