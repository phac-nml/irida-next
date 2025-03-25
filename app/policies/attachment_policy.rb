# frozen_string_literal: true

# Policy for attachments authorization
class AttachmentPolicy < ApplicationPolicy
  def read?
    if record.attachable.instance_of?(Sample) || record.attachable.instance_of?(Namespaces::ProjectNamespace)
      allowed_to?(:read?, record.attachable.project)
    elsif record.attachable.instance_of?(Group)
      allowed_to?(:read?, record.attachable)
    end
  end
end
