# frozen_string_literal: true

require 'test_helper'

module Groups
  class SamplesTest < ActionDispatch::IntegrationTest
    include ActionView::RecordIdentifier

    setup do
      @user = users(:john_doe)
      sign_in @user
      @group = groups(:group_one)
      @sample1 = samples(:sample1)
      @sample2 = samples(:sample2)
      @sample3 = samples(:sample3)
    end

    test 'index renders the samples table with headers and rows' do
      get group_samples_url(@group)

      assert_response :success
      assert_select 'h1', text: I18n.t('groups.samples.index.title')
      assert_samples_table_headers
      assert_select 'table tbody tr', count: 20
      assert_select "table tbody tr##{dom_id(@sample3)} td:nth-child(2)", text: /#{Regexp.escape(@sample3.name)}/
    end

    test 'index paginates the samples table' do
      get group_samples_url(@group, page: 2)

      assert_response :success
      assert_select 'table tbody tr', count: 6
      assert_select "table tbody tr##{dom_id(@sample3)}", count: 0
    end

    test 'index renders the data grid when the flag is enabled' do
      Flipper.enable(:data_grid_samples_table)

      get group_samples_url(@group)

      assert_response :success
      assert_samples_data_grid
    ensure
      Flipper.disable(:data_grid_samples_table)
    end

    test 'index renders samples for a group with linked groups and projects' do
      sign_in users(:david_doe)
      group = groups(:david_doe_group_four)

      get group_samples_url(group)

      assert_response :success
      assert_select 'h1', text: I18n.t('groups.samples.index.title')
      assert_select 'table tbody tr', count: 20
      assert_select "table tbody tr##{dom_id(@sample1)} td:nth-child(2)", text: /#{Regexp.escape(@sample1.name)}/
    end

    test 'user with role >= Analyst sees the workflow execution link' do
      get group_samples_url(@group)

      assert_response :success
      assert_select 'span', text: /#{Regexp.escape(I18n.t('projects.samples.index.workflows.button_sr'))}/
    end

    test 'user with role < Analyst does not see the workflow execution link' do
      sign_in users(:ryan_doe)

      get group_samples_url(@group)

      assert_response :success
      assert_select 'span',
                    text: /#{Regexp.escape(I18n.t('projects.samples.index.workflows.button_sr'))}/, count: 0
    end

    test 'user with role >= Analyst sees the sample actions dropdown' do
      get group_samples_url(@group)

      assert_response :success
      assert_select 'button[aria-label=?]', I18n.t('shared.samples.actions_dropdown.label')
    end

    test 'user with role < Analyst does not see the sample actions dropdown' do
      sign_in users(:ryan_doe)

      get group_samples_url(@group)

      assert_response :success
      assert_select 'button[aria-label=?]', I18n.t('shared.samples.actions_dropdown.label'), count: 0
    end

    test 'user with role >= Maintainer sees the clone samples action' do
      get group_samples_url(@group)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.clone')
    end

    test 'user with role < Maintainer does not see the clone samples action' do
      sign_in users(:ryan_doe)

      get group_samples_url(@group)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.clone'), count: 0
    end

    test 'user with role == Owner sees the delete samples action' do
      get group_samples_url(@group)

      assert_response :success
      assert_select 'button[role="menuitem"]', text: I18n.t('shared.samples.actions_dropdown.delete_samples')
    end

    test 'user with role < Owner does not see the delete samples action' do
      user = users(:joan_doe)
      sign_in user

      get group_samples_url(@group)

      assert_response :success
      assert_select 'button[aria-label=?]', I18n.t('shared.samples.actions_dropdown.label', locale: user.locale)
      assert_select 'button[role="menuitem"]',
                    text: I18n.t('shared.samples.actions_dropdown.delete_samples', locale: user.locale), count: 0
    end

    test 'cannot access group samples without authorization' do
      sign_in users(:user_no_access)

      get group_samples_url(@group)

      assert_response :unauthorized
    end

    test 'quick search filters the samples list by name' do
      get group_samples_url(@group, q: { name_or_puid_cont: 'Sample 1' })

      assert_response :success
      assert_select 'table tbody tr', count: 13
      assert_select "table tbody tr##{dom_id(@sample1)} td:nth-child(2)", text: /#{Regexp.escape(@sample1.name)}/
      assert_select "table tbody tr##{dom_id(@sample2)}", count: 0
    end
  end
end
