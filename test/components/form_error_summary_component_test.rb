# frozen_string_literal: true

require 'view_component_test_case'

class FormErrorSummaryComponentTest < ViewComponentTestCase
  test 'component does not render when there are no entries' do
    render_inline(FormErrorSummaryComponent.new(entries: []))

    assert_no_selector '.alert-component'
  end

  test 'entry builder returns no entries when the builder has no validation errors' do
    builder = build_form_builder('user', build_user)

    assert_empty FormErrorSummaryEntryBuilder.new(builder:).call
  end

  test 'component renders one linked entry per invalid field using all messages' do
    user = build_user
    user.errors.add(:email, :blank)
    user.errors.add(:email, :invalid)
    user.errors.add(:last_name, :blank)

    entries = FormErrorSummaryEntryBuilder.new(builder: build_form_builder('user', user)).call

    render_inline(FormErrorSummaryComponent.new(entries:))

    email_message = user.errors.full_messages_for(:email).to_sentence

    assert_selector '.alert-component', count: 1
    assert_selector 'div[data-controller="form-error-summary"][tabindex="-1"]', count: 1
    assert_no_selector '#sr-status'
    assert_selector 'h2',
                    text: I18n.t('general.form.error_summary.title', count: 2)
    assert_selector 'p', text: I18n.t('general.form.error_notification')
    assert_selector 'a[href="#user_email"]', text: email_message
    assert_selector 'a[href="#user_last_name"]', text: user.errors.full_messages_for(:last_name).first
    assert_selector 'a', text: email_message, count: 1
    assert_selector ".alert-component[class*='focus-within:outline-red-600']"
  end

  test 'component forwards caller-provided system arguments to the alert wrapper' do
    entries = [
      FormErrorSummaryEntryBuilder::Entry.new(
        attribute: :email,
        message: "Email can't be blank",
        target_id: 'user_email'
      )
    ]

    render_inline(
      FormErrorSummaryComponent.new(
        entries:,
        id: 'custom-summary',
        data: { testid: 'form-summary' },
        aria: { label: 'Form error summary' }
      )
    )

    assert_selector '.alert-component#custom-summary[data-testid="form-summary"][aria-label="Form error summary"]'
  end

  test 'entry builder derives nested builder target ids' do
    namespace = Namespaces::ProjectNamespace.new
    namespace.errors.add(:path, :taken)

    entry = FormErrorSummaryEntryBuilder.new(
      builder: build_form_builder('project[namespace_attributes]', namespace)
    ).call.first

    assert_equal :path, entry.attribute
    assert_equal 'project_namespace_attributes_path', entry.target_id
  end

  test 'override path uses validation attributes and raw target ids' do
    namespace = Namespaces::ProjectNamespace.new
    namespace.errors.add(:namespace, 'required')

    entries = FormErrorSummaryEntryBuilder.new(
      builder: build_form_builder('project[namespace_attributes]', namespace),
      target_overrides: { namespace: 'namespace-select' }
    ).call

    render_inline(FormErrorSummaryComponent.new(entries:))

    assert_selector 'a[href="#namespace-select"]', text: 'Namespace required'
  end

  test 'attribute overrides use custom label in generated messages' do
    user = build_user
    user.errors.add(:email, :blank)

    entry = FormErrorSummaryEntryBuilder.new(
      builder: build_form_builder('user', user),
      attribute_overrides: { email: 'Email address' }
    ).call.first

    assert_equal "Email address can't be blank", entry.message
  end

  private

  def build_form_builder(object_name, object)
    template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    ActionView::Helpers::FormBuilder.new(object_name, object, template, {})
  end

  def build_user
    User.new(
      email: 'test@example.com',
      first_name: 'Ada',
      last_name: 'Lovelace',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      locale: I18n.default_locale.to_s
    )
  end
end
