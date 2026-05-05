# frozen_string_literal: true

module UserOptInFeaturesTestHelper
  def with_user_opt_in_features(features)
    settings = ApplicationSetting.current || ApplicationSetting.create_from_defaults
    previous_features = settings.user_opt_in_features.deep_dup

    settings.update!(user_opt_in_features: features.deep_stringify_keys)

    yield settings
  ensure
    settings&.update!(user_opt_in_features: previous_features) if settings&.persisted?
  end

  def user_opt_in_feature_config(feature_key: :data_grid_samples_table, allowlist: 'all')
    {
      feature_key.to_s => {
        'allowlist' => allowlist,
        'name' => {
          'en' => 'Data Grid Samples Table',
          'fr' => 'Tableau de donnees des echantillons'
        },
        'description' => {
          'en' => 'Enable the new data grid for the samples table.',
          'fr' => "Activer la nouvelle grille de donnees pour le tableau d'echantillons."
        }
      }
    }
  end
end
