# frozen_string_literal: true

require 'test_helper'

class LinelistExportRowsQueryTest < ActiveSupport::TestCase
  LINELIST_EXPORT_ROWS_QUERY = <<~GRAPHQL
    query($namespaceId: ID!, $sampleIds: [ID!]!, $metadataKeys: [String!] = null) {
      linelistExportRows(
        namespaceId: $namespaceId
        sampleIds: $sampleIds
        metadataKeys: $metadataKeys
      ) {
        id
        puid
        name
        metadata
        project {
          puid
        }
      }
    }
  GRAPHQL

  test 'linelistExportRows returns rows for authorized analyst export from group namespace' do
    user = users(:john_doe)
    group = groups(:group_one)
    sample = samples(:sample30)

    result = IridaSchema.execute(
      LINELIST_EXPORT_ROWS_QUERY,
      context: { current_user: user },
      variables: {
        namespaceId: group.id.to_s,
        sampleIds: [sample.id.to_s],
        metadataKeys: ['metadatafield1']
      }
    )

    assert_nil result['errors'], result['errors'].inspect

    rows = result['data']['linelistExportRows']
    assert_equal 1, rows.length
    assert_equal sample.puid, rows[0]['puid']
    assert_equal sample.name, rows[0]['name']
    assert_equal sample.project.puid, rows[0]['project']['puid']
    assert_equal({ 'metadatafield1' => 'value1' }, rows[0]['metadata'])
  end

  test 'linelistExportRows rejects guest-only linked samples when exporting from group' do
    user = users(:private_ryan)
    group = groups(:group_alpha)
    sample = samples(:sampleBravo)

    result = IridaSchema.execute(
      LINELIST_EXPORT_ROWS_QUERY,
      context: { current_user: user },
      variables: {
        namespaceId: group.id.to_s,
        sampleIds: [sample.id.to_s]
      }
    )

    assert_not_nil result['errors']
    assert_equal I18n.t('services.data_exports.create.invalid_export_samples'),
                 result['errors'][0]['message']
  end

  test 'linelistExportRows works when exporting from a project namespace' do
    user = users(:john_doe)
    namespace = namespaces_project_namespaces(:project1_namespace)
    sample = samples(:sample30)

    result = IridaSchema.execute(
      LINELIST_EXPORT_ROWS_QUERY,
      context: { current_user: user },
      variables: {
        namespaceId: namespace.id.to_s,
        sampleIds: [sample.id.to_s],
        metadataKeys: []
      }
    )

    assert_nil result['errors'], result['errors'].inspect
    assert_equal 1, result['data']['linelistExportRows'].length
  end

  test 'linelistExportRows rejects export when user lacks export_data on namespace' do
    user = users(:david_doe)
    group = groups(:group_one)
    sample = samples(:sample1)

    result = IridaSchema.execute(
      LINELIST_EXPORT_ROWS_QUERY,
      context: { current_user: user },
      variables: {
        namespaceId: group.id.to_s,
        sampleIds: [sample.id.to_s]
      }
    )

    assert_not_nil result['errors']
    assert_equal 'unauthorized', result['errors'][0]['extensions']['code'].to_s
  end
end
