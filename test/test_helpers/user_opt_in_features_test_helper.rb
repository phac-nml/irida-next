# frozen_string_literal: true

# Shared helpers for configuring user opt-in feature settings in tests.
module UserOptInFeaturesTestHelper
  delegate :current_application_settings, to: :'Irida::CurrentSettings'

  def update_user_opt_in_features(features)
    current_application_settings.update!(user_opt_in_features: features)
  end

  def default_user_opt_in_features(allowlist: 'all', name_en: 'Data Grid Samples Table',
                                   description_en: 'Enable the new data grid for the samples table.',
                                   name_fr: nil, description_fr: nil)
    feature_name = { 'en' => name_en }
    feature_description = { 'en' => description_en }
    feature_name['fr'] = name_fr if name_fr
    feature_description['fr'] = description_fr if description_fr

    {
      'data_grid_samples_table' => {
        'allowlist' => allowlist,
        'name' => feature_name,
        'description' => feature_description
      }
    }
  end
end
