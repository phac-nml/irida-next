# frozen_string_literal: true

require 'test_helper'

module Groups
  class GroupsDashboardTest < ActionDispatch::IntegrationTest
    def setup
      @user = users(:alph_abet)
    end

    test 'can see the list of groups' do
      sign_in @user

      get dashboard_groups_path

      assert_response :success
      assert_select 'h1', text: I18n.t(:'dashboard.groups.index.title')

      assert_select 'div.treegrid-container' do
        assert_select 'div.treegrid-row', count: 20
        [*('z'..'g')].each do |letter|
          assert_select 'div.treegrid-row', text: /#{Regexp.escape(groups(:"group_#{letter}").name)}/
        end
      end

      get dashboard_groups_path, params: { page: 2 }

      assert_response :success
      assert_select 'nav.pagy ul li a[aria-current="page"]', text: '2'
      assert_select 'div.treegrid-container' do
        assert_select 'div.treegrid-row', count: 6
        [*('f'..'a')].each do |letter|
          assert_select 'div.treegrid-row', text: /#{Regexp.escape(groups(:"group_#{letter}").name)}/
        end
      end

      get dashboard_groups_path, params: { page: 1 }

      assert_response :success
      assert_select 'nav.pagy ul li a[aria-current="page"]', text: '1'
      assert_select 'div.treegrid-container' do
        assert_select 'div.treegrid-row', count: 20
        [*('z'..'g')].each do |letter|
          assert_select 'div.treegrid-row', text: /#{Regexp.escape(groups(:"group_#{letter}").name)}/
        end
      end
    end

    test 'can expand parent groups to see their children' do
      sign_in users(:john_doe)
      group1 = groups(:group_one)
      subgroup1 = groups(:subgroup1)

      get dashboard_groups_path, params: { all_groups_q: { s: 'name asc' } }

      assert_response :success
      assert_select "div#group_#{group1.id}", count: 1
      assert_select "div#group_#{subgroup1.id}", count: 0

      get dashboard_groups_path,
          params: {
            parent_id: group1.id,
            collapse: false,
            level: 1,
            posinset: 1,
            setsize: 20,
            tabindex: 0
          },
          as: :turbo_stream

      assert_response :success
      assert_select "turbo-stream[action='replace'][target='group_#{group1.id}']"
      assert_select "div#group_#{subgroup1.id}", count: 1
    end

    test 'can create a group from listing page' do
      sign_in @user
      name = 'New group from dashboard'
      path = "new-group-from-dashboard-#{SecureRandom.hex(4)}"

      get dashboard_groups_path

      assert_response :success
      assert_select "a[href='#{new_group_path}']", text: I18n.t(:'dashboard.groups.index.create_group_button')

      get new_group_path

      assert_response :success
      assert_select 'h1', text: I18n.t('groups.create.title')
      assert_select "input[name='group[name]']"
      assert_select "input[name='group[path]']"

      assert_difference -> { Group.count }, 1 do
        post groups_path, params: { group: { name:, path:, description: 'New group description' } }
      end

      assert_response :redirect
      follow_redirect!
      assert_response :success
      assert_select 'h1', text: name
    end

    test 'can search for a group by name or puid' do
      sign_in @user

      get dashboard_groups_path, params: { all_groups_q: { name_or_puid_cont: 'group a' } }

      assert_response :success
      assert_includes response.body, groups(:group_a).name
      assert_not_includes response.body, groups(:group_b).name

      get dashboard_groups_path, params: { all_groups_q: { name_or_puid_cont: groups(:group_b).puid } }

      assert_response :success
      assert_not_includes response.body, groups(:group_a).name
      assert_includes response.body, groups(:group_b).name

      get dashboard_groups_path, params: { all_groups_q: { name_or_puid_cont: 'z6z6z6' } }

      assert_response :success
      assert_select 'h2', text: I18n.t(:'components.viral.pagy.empty_state.title')
      assert_select 'div > span', text: I18n.t(:'components.viral.pagy.empty_state.description')
    end

    test 'can search for a public group by name or puid' do
      sign_in @user

      get dashboard_groups_path,
          params: { public: 'true', public_groups_q: { name_or_puid_cont: 'public group 1' } }

      assert_response :success
      assert_includes response.body, groups(:public_group1).name
      assert_not_includes response.body, groups(:public_group2).name

      get dashboard_groups_path,
          params: { public: 'true', public_groups_q: { name_or_puid_cont: groups(:public_group2).puid } }

      assert_response :success
      assert_not_includes response.body, groups(:public_group1).name
      assert_includes response.body, groups(:public_group2).name

      get dashboard_groups_path,
          params: { public: 'true', public_groups_q: { name_or_puid_cont: 'z6z6z6' } }

      assert_response :success
      assert_select 'h2', text: I18n.t(:'components.viral.pagy.empty_state.title')
      assert_select 'div > span', text: I18n.t(:'components.viral.pagy.empty_state.description')
    end

    test 'filtering renders flat list' do
      sign_in users(:john_doe)
      group1 = groups(:group_one)
      group3 = groups(:group_three)

      get dashboard_groups_path, params: { all_groups_q: { s: 'name asc' } }
      assert_response :success

      assert_select 'div.treegrid-container' do
        assert_select 'div.treegrid-row' do
          assert_select 'div.treegrid-row', text: /#{Regexp.escape(group1.name)}/ do
            assert_select "##{dom_id(group1)} button[aria-label='Expand']", count: 1
          end
          assert_select 'div.treegrid-row', text: /#{Regexp.escape(group3.name)}/ do
            assert_select "##{dom_id(group3)} button[aria-label='Expand']", count: 1
          end
        end
      end

      get dashboard_groups_path, params: { all_groups_q: { name_or_puid_cont: 'group' } }
      assert_response :success

      assert_select 'div.treegrid-container' do
        assert_select 'div.treegrid-row' do
          assert_select 'div.treegrid-row', text: /#{Regexp.escape(group1.name)}/ do
            assert_select "##{dom_id(group1)} button[aria-label='Expand']", count: 0
          end
          assert_select 'div.treegrid-row', text: /#{Regexp.escape(group3.name)}/ do
            assert_select "##{dom_id(group3)} button[aria-label='Expand']", count: 0
          end
        end
      end
    end

    test 'should display a samples count that includes samples from shared groups and projects' do
      sign_in users(:john_doe)
      group = groups(:group_three)

      get dashboard_groups_path, params: { all_groups_q: { s: 'created_at asc' } }

      assert_response :success
      assert_equal 4, group.aggregated_samples_count
      assert_select "#group_#{group.id}-samples-count", text: group.aggregated_samples_count.to_s
    end

    test 'can skip to content' do
      sign_in @user

      get dashboard_groups_path

      assert_response :success
      assert_select '#main-content-link[href="#main-content"]'
      assert_select '#main-content'
    end

    test 'should apply default sort when no sort specified' do
      sign_in @user

      get dashboard_groups_path

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:group_a).name

      get dashboard_groups_path, params: { public: 'true' }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:public_group1).name
    end

    test 'should sort groups by name descending' do
      sign_in @user

      get dashboard_groups_path, params: { all_groups_q: { s: 'name desc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:group_z).name

      get dashboard_groups_path, params: { public: 'true', public_groups_q: { s: 'name desc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:public_group10).name
    end

    test 'should sort groups by name ascending' do
      sign_in @user

      get dashboard_groups_path, params: { all_groups_q: { s: 'name asc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:group_a).name

      get dashboard_groups_path, params: { public: 'true', public_groups_q: { s: 'name asc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:public_group1).name
    end

    test 'should sort groups by updated_at descending' do
      sign_in @user

      get dashboard_groups_path, params: { all_groups_q: { s: 'updated_at desc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:group_a).name

      get dashboard_groups_path, params: { public: 'true', public_groups_q: { s: 'updated_at desc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:public_group1).name
    end

    test 'should sort groups by updated_at ascending' do
      sign_in @user

      get dashboard_groups_path, params: { all_groups_q: { s: 'updated_at asc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:group_z).name

      get dashboard_groups_path, params: { public: 'true', public_groups_q: { s: 'updated_at asc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:public_group10).name
    end

    test 'should sort groups by created_at ascending' do
      sign_in @user

      get dashboard_groups_path, params: { all_groups_q: { s: 'created_at asc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:group_z).name

      get dashboard_groups_path, params: { public: 'true', public_groups_q: { s: 'created_at asc' } }

      assert_response :success
      assert_includes first_treegrid_row_text, groups(:public_group10).name
    end

    test 'accessing groups index on invalid page causes pagy overflow redirect' do
      sign_in users(:john_doe)

      # Accessing page 50 (arbitrary number) when only < 50 pages exist should cause Pagy::RangeError
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

    private

    def first_treegrid_row_text
      Nokogiri::HTML(response.body).css('div.treegrid-row').first&.text.to_s # rubocop:disable Rails/ResponseParsedBody
    end
  end
end
