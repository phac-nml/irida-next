# frozen_string_literal: true

class FormErrorSummaryComponentPreview < ViewComponent::Preview
  def focus_demo
    render_with_template(locals: {
                           entries: [
                             entry(attribute: :email, message: "Email can't be blank", target_id: 'user_email'),
                             entry(attribute: :namespace,
                                   message: 'Namespace required',
                                   target_id: 'namespace-select')
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
