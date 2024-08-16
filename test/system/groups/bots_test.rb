# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class BotsTest < ApplicationSystemTestCase
    header_row_count = 1

    def setup
      @user = users(:john_doe)
      login_as @user
      @namespace = groups(:group_one)
    end

    test 'can see a table listing of group bot accounts' do
      visit group_bots_path(@namespace)

      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      assert_selector 'tr', count: 20 + header_row_count

      assert_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_selector 'tr', count: 1 + header_row_count

      assert_selector 'a', text: I18n.t(:'components.pagination.previous')
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/

      click_on I18n.t(:'components.pagination.previous')
      assert_selector 'tr', count: 20 + header_row_count
    end

    test 'can see an empty state for table listing of group bot accounts' do
      visit group_bots_path(groups(:group_two))

      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      assert_selector 'tr', count: 0

      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      within('div.empty_state_message') do
        assert_text I18n.t(:'groups.bots.index.bot_listing.empty_state.title')
        assert_text I18n.t(:'groups.bots.index.bot_listing.empty_state.description')
      end
    end

    test 'can create a new group bot account' do
      namespace = groups(:group_two)
      visit group_bots_path(namespace)

      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      assert_selector 'a', text: I18n.t(:'groups.bots.index.add_new_bot'), count: 1

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'groups.bots.index.bot_listing.empty_state.title')
        assert_text I18n.t(:'groups.bots.index.bot_listing.empty_state.description')
      end

      click_link I18n.t(:'groups.bots.index.add_new_bot')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'groups.bots.index.bot_listing.new_bot_modal.title')
        assert_selector 'p', text: I18n.t(:'groups.bots.index.bot_listing.new_bot_modal.description')

        fill_in 'Token Name', with: 'Uploader'
        find('#bot_access_level').find('option',
                                       text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        all('input[type=checkbox]').each(&:click)

        click_button I18n.t(:'groups.bots.index.bot_listing.new_bot_modal.submit')
      end

      assert_no_selector 'dialog[open]'

      within('#access-token-section') do
        bot_account_name = namespace.bots.last.email

        assert_selector 'h2', text: I18n.t('groups.bots.index.access_token_section.label', bot_name: bot_account_name)
        assert_selector 'p', text: I18n.t('groups.bots.index.access_token_section.description')
        assert_selector 'button', text: I18n.t('components.clipboard.copy')
      end

      assert_selector 'tr', count: 1 + header_row_count
    end

    test 'can\'t create a new group bot account without selecting scopes' do
      visit group_bots_path(groups(:group_two))

      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      assert_selector 'a', text: I18n.t(:'groups.bots.index.add_new_bot'), count: 1

      assert_selector 'tr', count: 0

      within('div.empty_state_message') do
        assert_text I18n.t(:'groups.bots.index.bot_listing.empty_state.title')
        assert_text I18n.t(:'groups.bots.index.bot_listing.empty_state.description')
      end

      click_link I18n.t(:'groups.bots.index.add_new_bot')

      within('dialog') do
        assert_selector 'h1', text: I18n.t(:'groups.bots.index.bot_listing.new_bot_modal.title')
        assert_selector 'p', text: I18n.t(:'groups.bots.index.bot_listing.new_bot_modal.description')

        fill_in 'Token Name', with: 'Uploader'
        find('#bot_access_level').find('option',
                                       text: I18n.t('activerecord.models.member.access_level.analyst')).select_option

        assert_html5_inputs_valid

        click_button I18n.t(:'groups.bots.index.bot_listing.new_bot_modal.submit')

        within('#new_bot_account-error-alert') do
          assert_text I18n.t(:'services.bots.create.required.scopes')
        end
      end
    end

    test 'can delete a group bot account' do
      visit group_bots_path(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      within('table') do
        within('table tbody tr:first-child td:last-child') do
          click_link 'Remove'
        end
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      assert_text I18n.t(:'groups.bots.destroy.success')

      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')
      assert_no_selector 'a', text: /\A#{I18n.t(:'components.pagination.next')}\Z/
    end

    test 'can view personal access tokens for bot account' do
      namespace_bot = namespace_bots(:group1_bot0)
      active_personal_tokens = namespace_bot.user.personal_access_tokens.active

      visit group_bots_path(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      table_row = find(:table_row, { 'Username' => namespace_bot.user.email })

      within table_row do
        click_link active_personal_tokens.count.to_s
      end

      within('dialog') do
        assert_selector 'h1', text: I18n.t('groups.bots.index.personal_access_tokens_listing_modal.title')
        assert_selector 'p',
                        text: I18n.t(
                          'groups.bots.index.personal_access_tokens_listing_modal.description',
                          bot_account: namespace_bot.user.email
                        )

        within('table') do
          assert_selector 'tr', count: 2
          token = active_personal_tokens.first

          table_row = find(:table_row, { 'Token name' => token.name })

          within table_row do
            assert_equal 'Valid PAT0', token.name
            assert_equal 'read_api, api', token.scopes.join(', ')

            assert_equal Time.zone.now.strftime(
              I18n.t('time.formats.full_date')
            ), token.created_at.strftime(
              I18n.t('time.formats.full_date')
            )

            assert_equal 10.days.from_now.to_date.strftime(
              I18n.t('time.formats.full_date')
            ), token.expires_at.strftime(
              I18n.t('time.formats.full_date')
            )
          end
        end
      end
    end

    test 'can generate a new personal access token for bot account' do
      namespace_bot = namespace_bots(:group1_bot0)

      visit group_bots_path(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      table_row = find(:table_row, { 'Username' => namespace_bot.user.email })

      within table_row do
        click_link 'Generate new token'
      end

      within('dialog') do
        assert_text I18n.t(
          'groups.bots.index.bot_listing.generate_personal_access_token_modal.title'
        )

        assert_text I18n.t('groups.bots.index.bot_listing.generate_personal_access_token_modal.description',
                           bot_account: namespace_bot.user.email)

        fill_in 'Token Name', with: 'Newest token'

        all('input[type=checkbox]').each(&:click)

        click_button I18n.t('groups.bots.index.bot_listing.generate_personal_access_token_modal.submit')
      end

      within('#access-token-section') do
        bot_account_name = namespace_bot.user.email
        assert_selector 'h2', text: I18n.t('groups.bots.index.access_token_section.label', bot_name: bot_account_name)
        assert_selector 'p', text: I18n.t('groups.bots.index.access_token_section.description')
        assert_selector 'button', text: I18n.t('components.clipboard.copy')
      end
    end

    test 'can revoke a personal access token' do
      namespace_bot = namespace_bots(:group1_bot0)
      active_personal_tokens = namespace_bot.user.personal_access_tokens.active
      token = nil

      visit group_bots_path(@namespace)
      assert_selector 'h1', text: I18n.t(:'groups.bots.index.title')
      assert_selector 'p', text: I18n.t(:'groups.bots.index.subtitle')

      table_row = find(:table_row, { 'Username' => namespace_bot.user.email })

      within table_row do
        click_link active_personal_tokens.count.to_s
      end

      within('dialog') do
        assert_selector 'h1', text: I18n.t('groups.bots.index.personal_access_tokens_listing_modal.title')
        assert_selector 'p',
                        text: I18n.t(
                          'groups.bots.index.personal_access_tokens_listing_modal.description',
                          bot_account: namespace_bot.user.email
                        )

        within('table') do
          assert_selector 'tr', count: 2
          token = active_personal_tokens.first

          table_row = find(:table_row, { 'Token name' => token.name })

          within table_row do
            click_link 'Revoke'
          end
        end
      end

      within('#turbo-confirm[open]') do
        click_button 'Confirm'
      end

      within('dialog') do
        within('#personal-access-token-alert') do
          assert_text I18n.t('groups.bots.personal_access_tokens.revoke.success', pat_name: token.name)
        end
      end
    end
  end
end
