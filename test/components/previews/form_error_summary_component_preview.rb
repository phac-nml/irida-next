# frozen_string_literal: true

class FormErrorSummaryComponentPreview < ViewComponent::Preview
  def focus_demo
    render_with_template(locals: {
                           entries: [
                             entry(attribute: :email, message: "Email can't be blank", target_id: 'user_email'),
                             entry(attribute: :namespace,
                                   message: 'Namespace required',
                                   target_id: 'namespace-select'),

                             # Exercise focus fallbacks:
                             # - datepicker v2 input renders as "#{id}-input"
                             entry(attribute: :expires_at,
                                   message: "Expiration date can't be blank",
                                   target_id: 'expires_at'),
                             # - multi-checkbox renders as "#{baseId}_<value>"
                             entry(attribute: :scopes,
                                   message: "Scopes can't be blank",
                                   target_id: 'personal_access_token_scopes')
                           ]
                         })
  end

  private

  def entry(attribute:, message:, target_id:)
    FormErrorSummaryEntryBuilder::Entry.new(
      attribute:,
      message:,
      target_id:
    )
  end
end
