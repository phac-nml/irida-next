# frozen_string_literal: true

require 'view_component_test_case'

class UserAvatarComponentTest < ViewComponentTestCase
  setup do
    @user = users(:john_doe)
  end

  test 'renders medium avatar with initials' do
    render_inline(UserAvatarComponent.new(user: @user))

    assert_selector('span.avatar')
    assert_selector('span.w-12.h-12')
    assert_text('JD')
    assert_selector('span[role="img"][aria-label="John Doe"]')
  end

  test 'renders xs avatar' do
    render_inline(UserAvatarComponent.new(user: @user, size: :xs))

    assert_selector('span.w-6.h-6')
    assert_text('JD')
  end

  test 'renders small avatar' do
    render_inline(UserAvatarComponent.new(user: @user, size: :small))

    assert_selector('span.w-8.h-8')
    assert_text('JD')
  end

  test 'renders large avatar' do
    render_inline(UserAvatarComponent.new(user: @user, size: :large))

    assert_selector('span.w-16.h-16')
    assert_text('JD')
  end

  test 'renders shell when initials are blank' do
    user = User.new(first_name: '', last_name: '', email: 'blank@localhost')

    render_inline(UserAvatarComponent.new(user: user))

    assert_selector('span.avatar[role="img"]')
    assert_no_text('JD')
  end

  test 'renders decorative avatar without img role' do
    render_inline(UserAvatarComponent.new(user: @user, decorative: true))

    assert_selector('span.avatar[aria-hidden="true"]')
    assert_no_selector('span[role="img"]')
    assert_text('JD')
  end
end
