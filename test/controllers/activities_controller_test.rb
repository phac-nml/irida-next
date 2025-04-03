# frozen_string_literal: true

require 'test_helper'

# Tests for the ActivitiesController
class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:john_doe)
    sign_in @user
    @namespace = namespaces_project_namespaces(:project1_namespace)
    @sample = samples(:sample1)
    @sample2 = samples(:sample2)
  end

  test 'should render correct activity dialog depending on dialog_type param' do
    activities = @namespace.human_readable_activity(@namespace.retrieve_project_activity).reverse

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.samples.transfer_html'
    end

    get activity_path(activity_to_render[:id], dialog_type: 'samples_transfer', format: :turbo_stream)

    assert_response :success

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.samples.clone_html'
    end

    get activity_path(activity_to_render[:id], dialog_type: 'samples_clone', format: :turbo_stream)

    assert_response :success

    Samples::DestroyService.new(@namespace.project, users(:james_doe), { sample_ids: [@sample.id] }).execute

    activities = @namespace.human_readable_activity(@namespace.retrieve_project_activity).reverse

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.samples.destroy_multiple_html'
    end

    users(:james_doe).destroy!

    get activity_path(activity_to_render[:id], dialog_type: 'samples_destroy', format: :turbo_stream)

    assert_response :success

    Samples::DestroyService.new(@namespace.project, @user, { sample_ids: [@sample2.id] }).execute

    activities = @namespace.human_readable_activity(@namespace.retrieve_project_activity).reverse

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.samples.destroy_multiple_html'
    end

    get activity_path(activity_to_render[:id], dialog_type: 'samples_destroy', format: :turbo_stream)

    assert_response :success
  end

  test 'should display error alert if dialog type is unable to be loaded' do
    activities = @namespace.human_readable_activity(@namespace.retrieve_project_activity).reverse

    activity_to_render = activities.find do |a|
      a[:key] == 'activity.namespaces_project_namespace.samples.transfer_html'
    end

    get activity_path(activity_to_render[:id], dialog_type: 'samples_newtransfer', format: :turbo_stream)

    assert_redirected_to root_path
    assert_equal I18n.t('activities.show.error', dialog_type: 'samples_newtransfer'), flash[:alert]
  end
end
