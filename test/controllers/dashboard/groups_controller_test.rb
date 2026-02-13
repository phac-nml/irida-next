# frozen_string_literal: true

require 'test_helper'

module Dashboard
  class GroupsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include DashboardSortingHelper

    setup do
      @user = users(:alph_abet)
    end

    test 'should get index' do
      sign_in users(:john_doe)

      get dashboard_groups_path
      assert_response :success

      w3c_validate 'Groups Dashboard'
    end

    test 'should apply default sort when no sort specified' do
      sign_in @user

      get dashboard_groups_path

      assert_response :success
      assert_active_sort('q', 'created_at desc')
    end

    test 'should sort groups by name descending' do
      sign_in @user

      get dashboard_groups_path, params: { q: { s: 'name desc' } }

      assert_response :success
      assert_active_sort('q', 'name desc')
      assert_includes first_treegrid_row_text, groups(:group_z).name
    end

    test 'should sort groups by name ascending' do
      sign_in @user

      get dashboard_groups_path, params: { q: { s: 'name asc' } }

      assert_response :success
      assert_active_sort('q', 'name asc')
      assert_includes first_treegrid_row_text, groups(:group_a).name
    end

    test 'should sort groups by updated_at descending' do
      sign_in @user

      get dashboard_groups_path, params: { q: { s: 'updated_at desc' } }

      assert_response :success
      assert_active_sort('q', 'updated_at desc')
      assert_includes first_treegrid_row_text, groups(:group_a).name
    end

    test 'should sort groups by updated_at ascending' do
      sign_in @user

      get dashboard_groups_path, params: { q: { s: 'updated_at asc' } }

      assert_response :success
      assert_active_sort('q', 'updated_at asc')
      assert_includes first_treegrid_row_text, groups(:group_z).name
    end

    test 'should sort groups by created_at ascending' do
      sign_in @user

      get dashboard_groups_path, params: { q: { s: 'created_at asc' } }

      assert_response :success
      assert_active_sort('q', 'created_at asc')
      assert_includes first_treegrid_row_text, groups(:group_z).name
    end

    test 'accessing groups index on invalid page causes pagy overflow redirect' do
      sign_in users(:john_doe)

      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::OverflowError
      # The rescue_from handler should redirect to first page with page=1 and limit=20
      get dashboard_groups_path(page: 50)

      # Should be redirected to first page
      assert_response :redirect
      # Check both page and limit are in the redirect URL (order may vary)
      assert_match(/page=1/, response.location)
      assert_match(/limit=20/, response.location)

      # Follow the redirect and verify it's successful
      follow_redirect!
      assert_response :success
    end
  end
end
