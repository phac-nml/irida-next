# frozen_string_literal: true

require 'test_helper'

class ProjectNamespaceFieldsPartialTest < ActionView::TestCase
  test 'namespace inline error only shows namespace messages' do
    user = users(:john_doe)
    @project = Project.new
    namespace = @project.build_namespace(name: 'a', path: 'new-project', parent_id: user.namespace.id)
    namespace.errors.add(:namespace, I18n.t('services.projects.create.namespace_required'))
    namespace.errors.add(:name, 'is too short')

    render partial: 'projects/project_namespace_fields',
           locals: {
             builder: build_form_builder('project[namespace_attributes]', namespace),
             authorized_namespaces: [user.namespace]
           }

    assert_select '#project_namespace_attributes_namespace_error', text: /Namespace required/
    assert_select '#project_namespace_attributes_namespace_error', text: /Name is too short/, count: 0
    assert_select '#project_namespace_attributes_name_error', text: /Name is too short/
  end

  private

  def build_form_builder(object_name, object)
    ActionView::Helpers::FormBuilder.new(object_name, object, self, {})
  end

  def current_user
    users(:john_doe)
  end

  def params
    ActionController::Parameters.new
  end
end
