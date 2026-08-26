# frozen_string_literal: true

require 'test_helper'

module Projects
  class MembersTest < ActionDispatch::IntegrationTest
    PAGE_SIZE = Pagy::OPTIONS[:limit]

    def setup
      @user = users(:john_doe)
      @namespace = namespaces_user_namespaces(:john_doe_namespace)
      @project = projects(:john_doe_project2)
      @members_count = members.select { |member| member.namespace == @project.namespace }.count
      @member_john = members(:project_two_member_john_doe)
      @member_james = members(:project_two_member_james_doe)
      @member_joan = members(:project_two_member_joan_doe)
      @member_jean = members(:project_two_member_jean_doe)
      @member_ryan = members(:project_two_member_ryan_doe)
    end

    test 'can see the list of project members' do
      sign_in @user
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:project26)
      members_count = members.select { |member| member.namespace == project.namespace }.count

      get namespace_project_members_path(namespace, project)

      assert_response :success

      assert_select 'h1',
                    I18n.t(:'projects.members.index.title')
      assert_select 'p', I18n.t(:'projects.members.index.subtitle',
                                namespace_type: project.namespace.class.model_name.human,
                                namespace_name: project.namespace.name)

      assert_select 'button',
                    I18n.t('projects.members.index.add')
      assert_select 'button',
                    I18n.t('projects.members.index.invite_group')

      assert_select "turbo-frame#members[src='#{namespace_project_members_path(
        namespace, project,
        format: :turbo_stream
      )}'][loading='lazy']"

      get namespace_project_members_path(namespace, project), as: :turbo_stream

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select "input[placeholder='#{I18n.t('projects.members.member_listing.search.placeholder')}']"
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'thead' do
              assert_select 'tr' do
                assert_select 'th', I18n.t(:'members.table_component.user_email')
                assert_select 'th', I18n.t(:'members.table_component.access_level')
                assert_select 'th', I18n.t(:'members.table_component.namespace_name')
                assert_select 'th', I18n.t(:'members.table_component.updated_at')
                assert_select 'th', I18n.t(:'members.table_component.expires_at')
                assert_select 'th', I18n.t(:'members.table_component.action')
              end
            end
            assert_select 'tbody' do
              assert_select 'tr', count: PAGE_SIZE
            end
          end
        end
      end
      assert_select 'turbo-stream[action="update"][target="members_pagination"]' do
        assert_select 'span', text: I18n.t('components.viral.pagy.pagination_component.next')
        assert_select 'span[class="pagy info"]',
                      text: "Displaying items 1-#{PAGE_SIZE} of #{members_count} in total"
      end
    end

    test 'can see list of project members which are inherited from parent group' do
      sign_in @user
      project = projects(:project21)
      parent_namespace = groups(:group_one)

      get namespace_project_members_path(parent_namespace, project), as: :turbo_stream

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select "input[placeholder='#{I18n.t('projects.members.member_listing.search.placeholder')}']"
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select 'tr', count: parent_namespace.group_members.count
              assert_select 'td:nth-child(3) > div > a', text: I18n.t('activerecord.models.member.direct'), count: 0
              assert_select 'td:nth-child(3) > div > a', text: parent_namespace.name,
                                                         count: parent_namespace.group_members.count
            end
          end
        end
      end
    end

    test 'lists the correct membership when user is a direct member of the project as well as an inherited member through a group' do # rubocop:disable Layout/LineLength
      sign_in @user
      project = projects(:project24)
      parent_namespace = groups(:group_one)
      project_member = members(:project_twenty_four_member_ryan_doe) # user is also a member of the parent group

      get namespace_project_members_path(parent_namespace, project), as: :turbo_stream

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select "input[placeholder='#{I18n.t('projects.members.member_listing.search.placeholder')}']"
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select "tr#member_#{project_member.id}" do
                assert_select 'td:nth-child(2)',
                              I18n.t("members.access_levels.level_#{project_member.access_level}")
                assert_select 'td:nth-child(3)', text: parent_namespace.name, count: 0
                assert_select 'td:nth-child(3)', text: I18n.t('activerecord.models.member.direct'), count: 1
              end
            end
          end
        end
      end
    end

    test 'should apply default sort and support sorting project members' do
      sign_in @user

      owner_emails = [members(:project_two_member_james_doe).user.email,
                      members(:project_two_member_john_doe).user.email]

      get namespace_project_members_path(@namespace, @project, format: :turbo_stream)
      assert_response :success
      assert_sort_state(1, 'ascending')
      assert_first_rows_include(@member_james.user.email, @member_jean.user.email,
                                row_scope: '#members-table-body')

      get namespace_project_members_path(@namespace, @project, format: :turbo_stream,
                                                               members_q: { s: 'user_email desc' })
      assert_response :success
      assert_sort_state(1, 'descending')
      assert_first_rows_include(@member_ryan.user.email, @member_john.user.email,
                                row_scope: '#members-table-body')

      get namespace_project_members_path(@namespace, @project, format: :turbo_stream,
                                                               members_q: { s: 'access_level asc' })
      assert_response :success
      assert_sort_state(2, 'ascending')
      member_emails = Nokogiri::HTML(response.body).css('#members-table-body tr td:first-child').filter_map do |node| # rubocop:disable Rails/ResponseParsedBody
        node.text[/[A-Za-z0-9_.+-]+@[A-Za-z0-9\-.]+/]
      end
      assert_equal @member_ryan.user.email, member_emails.first
      assert_includes owner_emails, member_emails.last

      get namespace_project_members_path(@namespace, @project, format: :turbo_stream,
                                                               members_q: { s: 'access_level desc' })
      assert_response :success
      assert_sort_state(2, 'descending')
      member_emails = Nokogiri::HTML(response.body).css('#members-table-body tr td:first-child').filter_map do |node| # rubocop:disable Rails/ResponseParsedBody
        node.text[/[A-Za-z0-9_.+-]+@[A-Za-z0-9\-.]+/]
      end
      assert_includes owner_emails, member_emails.first
      assert_equal @member_ryan.user.email, member_emails.last

      get namespace_project_members_path(@namespace, @project, format: :turbo_stream,
                                                               members_q: { s: 'expires_at asc' })
      assert_response :success
      assert_sort_state(5, 'ascending')
      assert_first_rows_include(@member_joan.user.email, @member_ryan.user.email,
                                row_scope: '#members-table-body')
    end

    test 'cannot access project members without proper access' do
      sign_in users(:david_doe)

      get namespace_project_members_path(@namespace, @project)

      assert_response :unauthorized
    end

    test 'can add a member to the project with proper access' do
      sign_in @user
      user_to_add = users(:jane_doe)

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      assert_select 'turbo-frame#new_member_dialog' do
        get new_namespace_project_member_path(@namespace, @project)
        assert_response :success

        assert_select 'div#new-member-dialog' do
          assert_select 'h1', text: I18n.t('projects.members.new.title')
        end
      end

      assert_difference -> { @project.namespace.project_members.count } do
        post namespace_project_members_path(@namespace, @project),
             params: { member: {
               user_id: user_to_add.id,
               namespace_id: @project.namespace.id,
               created_by_id: @user.id,
               access_level: Member::AccessLevel::ANALYST
             } },
             as: :turbo_stream
      end

      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(:'concerns.membership_actions.create.success',
                                                                      user: user_to_add.email)}"
      end
    end

    test 'can not add a member to the project due to insufficient permissions' do
      sign_in users(:ryan_doe)
      user_to_add = users(:jane_doe)

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      assert_no_difference -> { @project.namespace.project_members.count } do
        post namespace_project_members_path(@namespace, @project), params: {
          member: {
            user_id: user_to_add.id,
            access_level: Member::AccessLevel::ANALYST
          }
        }
      end

      assert_response :unauthorized
    end

    test 'cannot add a member to the project with invalid expiration date' do
      sign_in @user
      user_to_add = users(:jane_doe)

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      assert_select 'turbo-frame#new_member_dialog' do
        get new_namespace_project_member_path(@namespace, @project)
        assert_response :success

        assert_select 'div#new-member-dialog' do
          assert_select 'h1', text: I18n.t('projects.members.new.title')
        end
      end

      invalid_expiry_date = '2025-01-01'

      assert_no_difference -> { @project.namespace.project_members.count } do
        post namespace_project_members_path(@namespace, @project),
             params: { member: {
               user_id: user_to_add.id,
               namespace_id: @project.namespace.id,
               created_by_id: @user.id,
               access_level: Member::AccessLevel::ANALYST,
               expires_at: invalid_expiry_date
             } },
             as: :turbo_stream
      end

      assert_response :unprocessable_content

      assert_select 'a',
                    text: /#{I18n.t('errors.messages.date_greater_than', date: Time.zone.today)}/
      assert_select "div[class='form-field invalid']"
    end

    test 'cannot add a member to the project with invalid user id' do
      sign_in @user
      user_to_add_id = 'abc3-12d4-sdf3-1234'

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      assert_select 'turbo-frame#new_member_dialog' do
        get new_namespace_project_member_path(@namespace, @project)
        assert_response :success

        assert_select 'div#new-member-dialog' do
          assert_select 'h1', text: I18n.t('projects.members.new.title')
        end
      end

      assert_no_difference -> { @project.namespace.project_members.count } do
        post namespace_project_members_path(@namespace, @project),
             params: { member: {
               user_id: user_to_add_id,
               created_by_id: @user.id,
               access_level: Member::AccessLevel::ANALYST
             } },
             as: :turbo_stream
      end

      assert_response :unprocessable_content

      assert_select 'a', text:
            I18n.t(:'errors.format',
                   attribute: Member.human_attribute_name(:user_id),
                   message: I18n.t(:'errors.messages.required'))

      assert_select "div[class='form-field invalid']"
    end

    test 'invalid member create focuses the summary and linked custom control' do
      sign_in @user

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      I18n.t(:'errors.format',
             attribute: Member.human_attribute_name(:user_id),
             message: I18n.t(:'errors.messages.required'))

      post namespace_project_members_path(@namespace, @project),
           params: { member: {
             access_level: Member::AccessLevel::ANALYST
           } },
           as: :turbo_stream

      assert_response :unprocessable_content
      assert_select 'turbo-stream[action="update"][target="flashes"]', count: 0
    end

    test 'can remove a member from the project' do
      sign_in @user
      project_member = members(:project_two_member_ryan_doe)

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      assert_difference -> { @project.namespace.project_members.count }, -1 do
        delete namespace_project_member_path(@namespace, @project, project_member), as: :turbo_stream
      end

      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t(
                            :'concerns.membership_actions.destroy.success',
                            user: project_member.user.email
                          )}"
          end
        end
      end
    end

    test 'can remove a member from the project that is under a user namespace' do
      sign_in @user
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:john_doe_project4)
      project_member = members(:project_four_member_joan_doe)

      get namespace_project_members_path(namespace, project)
      assert_response :success

      assert_difference -> { project.namespace.project_members.count }, -1 do
        delete namespace_project_member_path(namespace, project, project_member), as: :turbo_stream
      end

      assert_response :success

      assert_select 'turbo-stream[action="append"][target="flashes"]' do
        assert_select 'template' do
          assert_select 'div[role="alert"]' do
            assert_select 'div',
                          "#{I18n.t('common.statuses.success')}: #{I18n.t(
                            :'concerns.membership_actions.destroy.success',
                            user: project_member.user.email
                          )}"
          end
        end
      end
    end

    test 'cannot remove a member with with insufficient permissions' do
      sign_in users(:joan_doe)

      assert_no_difference -> { @project.namespace.project_members.count } do
        delete namespace_project_member_path(@namespace, @project, @member_james), as: :turbo_stream
      end

      assert_response :unprocessable_content
    end

    test 'can leave a project that is under a user namespace where user is the only owner "member" of the project' do
      user = users(:user25)
      sign_in user
      namespace = namespaces_user_namespaces(:john_doe_namespace)
      project = projects(:project26)
      project_member = members(:project_twenty_six_group_member25)

      get namespace_project_members_path(namespace, project)
      assert_response :success

      assert_difference -> { project.namespace.project_members.count }, -1 do
        delete namespace_project_member_path(namespace, project, project_member), as: :turbo_stream
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'concerns.membership_actions.destroy.leave_success', name: project.name
                      )}"
      end
    end

    test 'can remove themselves as a member from the project' do
      sign_in @user

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      assert_difference -> { @project.namespace.project_members.count }, -1 do
        delete namespace_project_member_path(@namespace, @project, @member_john), as: :turbo_stream
      end

      follow_redirect!
      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(
                        'concerns.membership_actions.destroy.leave_success', name: @project.name
                      )}"
      end
    end

    test 'can update member\'s access level to another access level' do
      sign_in @user
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_michelle_doe)

      get edit_namespace_project_member_path(namespace, project, project_member), as: :turbo_stream
      assert_response :success

      Timecop.travel(Time.zone.now + 5) do
        patch namespace_project_member_path(namespace, project, project_member),
              params: { member: {
                access_level: Member::AccessLevel::ANALYST
              }, format: :turbo_stream }

        assert_response :success

        assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
          assert_select 'div',
                        "#{I18n.t('common.statuses.success')}: #{I18n.t(:'concerns.membership_actions.update.success',
                                                                        user_email: project_member.user.email)}"
        end
      end
    end

    test 'cannot update member\'s access level to a lower level than what they have assigned in parent group' do
      sign_in @user
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_james_doe)
      user = project_member.user.email
      access_level_from_group = I18n.t(
        "members.access_levels.level_#{members(:group_five_member_james_doe).access_level}"
      )

      get edit_namespace_project_member_path(namespace, project, project_member), as: :turbo_stream
      assert_response :success

      patch namespace_project_member_path(namespace, project, project_member),
            params: { member: {
              access_level: Member::AccessLevel::GUEST
            }, format: :turbo_stream }

      assert_response :unprocessable_content

      text = I18n.t(
        'activerecord.errors.models.member.attributes.access_level.invalid', user: user,
                                                                             group_name: namespace.name,
                                                                             access_level: access_level_from_group
      )

      assert_select 'a', text: /#{text}/
    end

    test 'can update member expiration' do
      sign_in @user
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_michelle_doe)
      expiry_date = (Time.zone.today + 1).strftime('%Y-%m-%d')

      get edit_namespace_project_member_path(namespace, project, project_member), as: :turbo_stream
      assert_response :success

      patch namespace_project_member_path(namespace, project, project_member), params: {
        member: {
          expires_at: expiry_date
        }, format: :turbo_stream
      }

      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(:'concerns.membership_actions.update.success',
                                                                      user_email: project_member.user.email)}"
      end
    end

    test 'invalid expiration date should not update member expiration' do
      sign_in @user
      project = projects(:project22)
      namespace = groups(:group_five)
      project_member = members(:project_twenty_two_member_michelle_doe)
      invalid_expiry_date = '2025-01-01'

      get edit_namespace_project_member_path(namespace, project, project_member), as: :turbo_stream
      assert_response :success

      patch namespace_project_member_path(namespace, project, project_member), params: {
        member: {
          expires_at: invalid_expiry_date
        }, format: :turbo_stream
      }
      assert_response :unprocessable_content

      assert_select 'a',
                    text: /#{I18n.t('errors.messages.date_greater_than', date: Time.zone.today)}/
      assert_select "div[class='form-field invalid']"

      invalid_expiry_date = 'invalid_date'

      patch namespace_project_member_path(namespace, project, project_member), params: {
        member: {
          expires_at: invalid_expiry_date
        }, format: :turbo_stream
      }
      assert_response :unprocessable_content

      text = "#{I18n.t('activerecord.attributes.member.expires_at')} #{I18n.t('common.date.errors.invalid_input')}"

      assert_select 'a', text: text
      assert_select "div[class='form-field invalid']"
    end

    test 'cannot update membership' do
      sign_in users(:ryan_doe)

      get edit_namespace_project_member_path(@namespace, @project, @member_john), as: :turbo_stream
      assert_response :unauthorized

      assert_no_difference -> { @member_john.reload.access_level } do
        patch namespace_project_member_path(@namespace, @project, @member_john), params: {
          member: {
            access_level: Member::AccessLevel::ANALYST
          }, format: :turbo_stream
        }
      end

      assert_response :unauthorized
    end

    test 'can add a group bot to a project' do
      user = users(:user29)
      sign_in user
      namespace_bot = namespace_bots(:group1_bot0)
      namespace = namespaces_user_namespaces(:user29_namespace)
      project = projects(:user29_project1)

      get namespace_project_members_path(namespace, project)
      assert_response :success

      assert_select 'turbo-frame#new_member_dialog' do
        get new_namespace_project_member_path(namespace, project)
        assert_response :success

        assert_select 'div#new-member-dialog' do
          assert_select 'h1', text: I18n.t('projects.members.new.title')
        end
      end

      assert_difference -> { project.namespace.project_members.count } do
        post namespace_project_members_path(namespace, project),
             params: { member: {
               user_id: namespace_bot.user.id,
               namespace_id: project.namespace.id,
               created_by_id: user.id,
               access_level: Member::AccessLevel::UPLOADER
             } },
             as: :turbo_stream
      end

      assert_response :success

      assert_select "div[role='alert'][aria-live='assertive'][data-viral--flash-type-value='success']" do
        assert_select 'div',
                      "#{I18n.t('common.statuses.success')}: #{I18n.t(:'concerns.membership_actions.create.success',
                                                                      user: namespace_bot.user.email)}"
      end
    end

    test 'cannot add a project bot to another project' do
      user = users(:user29)
      sign_in user
      namespace_bot = namespace_bots(:project1_bot0)
      namespace = namespaces_user_namespaces(:user29_namespace)
      project = projects(:user29_project1)

      get namespace_project_members_path(namespace, project)
      assert_response :success

      assert_select 'turbo-frame#new_member_dialog' do
        get new_namespace_project_member_path(namespace, project)
        assert_response :success

        assert_select 'div#new-member-dialog' do
          assert_select 'h1', text: I18n.t('projects.members.new.title')
        end
      end

      assert_no_difference -> { project.namespace.project_members.count } do
        post namespace_project_members_path(namespace, project),
             params: { member: {
               user_id: namespace_bot.user.id,
               namespace_id: project.namespace.id,
               created_by_id: user.id,
               access_level: Member::AccessLevel::UPLOADER
             } },
             as: :turbo_stream
      end

      assert_response :unprocessable_entity
    end

    test 'can search members by username' do
      sign_in @user

      get namespace_project_members_path(@namespace, @project), as: :turbo_stream
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select 'tr', count: 5
            end
          end
        end
      end

      get namespace_project_members_path(@namespace, @project),
          params: { members_q: { user_email_cont: @member_james.user.email } },
          as: :turbo_stream
      assert_response :success

      assert_select 'turbo-stream[action="update"][target="members"]' do
        assert_select 'template' do
          assert_select 'table' do
            assert_select 'tbody' do
              assert_select 'tr', count: 1
            end
          end
        end
      end
    end

    test 'can switch between members and shared groups tabs' do
      sign_in @user

      get namespace_project_members_path(@namespace, @project)
      assert_response :success

      # Members tab should be rendered and be the default
      assert_select '[role="tab"]#members-tab[aria-selected="true"]'
      assert_select '[role="tabpanel"]#members-panel:not([hidden])'
      assert_select '[role="tab"]#groups-tab[aria-selected="false"]'

      get namespace_project_members_path(@namespace, @project, tab: 'invited_groups')
      assert_response :success

      assert_select '[role="tab"]#members-tab[aria-selected="false"]'
      assert_select '[role="tabpanel"]#members-panel[hidden]'
      assert_select '[role="tab"]#groups-tab[aria-selected="true"]'
      assert_select '[role="tabpanel"]#groups-panel:not([hidden])'
    end
  end
end
