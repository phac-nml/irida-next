# frozen_string_literal: true

require 'view_component_test_case'

class AvatarComponentTest < ViewComponentTestCase
  setup do
    @user = users(:john_doe)
  end

  test 'renders medium avatar with initials' do
    render_inline(user_avatar)

    assert_selector('span.avatar')
    assert_selector('span.w-12.h-12')
    assert_text('JD')
    assert_selector('span[role="img"][aria-label="John Doe"]')
  end

  test 'renders xs avatar' do
    render_inline(user_avatar(size: :xs))

    assert_selector('span.w-6.h-6')
    assert_text('JD')
  end

  test 'renders small avatar' do
    render_inline(user_avatar(size: :small))

    assert_selector('span.w-8.h-8')
    assert_text('JD')
  end

  test 'renders large avatar' do
    render_inline(user_avatar(size: :large))

    assert_selector('span.w-16.h-16')
    assert_text('JD')
  end

  test 'renders shell when initials are blank' do
    user = User.new(first_name: '', last_name: '', email: 'blank@localhost')

    render_inline(user_avatar(user: user))

    assert_selector('span.avatar[role="img"]')
    assert_no_text('JD')
  end

  test 'renders decorative avatar without img role' do
    render_inline(user_avatar(decorative: true))

    assert_selector('span.avatar[aria-hidden="true"]')
    assert_no_selector('span[role="img"]')
    assert_text('JD')
  end

  test 'renders label-only avatar' do
    render_inline(AvatarComponent.new(label: 'Outbreak 2021'))

    assert_selector('span.avatar[role="img"][aria-label="Outbreak 2021"]')
    assert_text('O')
  end

  test 'renders linked avatar without img role' do
    render_inline(AvatarComponent.new(label: 'Outbreak 2021', url: 'https://example.com'))

    assert_selector('a.avatar[href="https://example.com"][aria-label="Outbreak 2021"]')
    assert_no_selector('a[role="img"]')
  end

  test 'raises when label is missing' do
    error = assert_raises(ArgumentError) do
      AvatarComponent.new(label: '')
    end

    assert_equal 'label is required', error.message
  end

  private

  def user_avatar(user: @user, **)
    AvatarComponent.new(
      label: user.full_name.presence || user.email,
      initials: user.avatar_initials,
      colour_seed: "#{user.id}-#{user.email}",
      **
    )
  end
end
