# frozen_string_literal: true

# Migration to add template id to template destroy activities
class AddTemplateIdToTemplateDestroyActivities < ActiveRecord::Migration[7.2]
  def change
    activity_keys = %w[group.metadata_template.destroy namespaces_project_namespace.metadata_template.destroy]
    activities = PublicActivity::Activity.where(key: activity_keys)

    activities.each do |activity|
      template_id = MetadataTemplate.with_deleted.find_by(name: activity.parameters[:template_name],
                                                          namespace_id: activity.parameters[:namespace_id])&.id

      unless template_id.nil?
        activity.parameters['template_id'] = template_id
        activity.save
      end
    end
  end
end
