const graphQLUrl = "/api/graphql";

const GROUP_SAMPLES_QUERY = `
  query($filter: SampleFilter, $group_id: ID!) {
    samples(filter: $filter, groupId: $group_id) {
    nodes {
        name
        puid
      }
      totalCount
    }
  }
`;

const UPDATE_SAMPLE_METADATA_MUTATION = `
  mutation ($samplePuid: ID!, $metadata: JSON!) {
    updateSampleMetadata(
      input: { samplePuid: $samplePuid, metadata: $metadata }
    ) {
      sample {
        id
        name
        description
        metadata
      }
      status
      errors {
        path
        message
      }
    }
  }
`;

async function groupSamples(groupId, filter = {}) {
  try {
    const response = await fetch(graphQLUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        query: GROUP_SAMPLES_QUERY,
        variables: {
          group_id: groupId,
          filter: filter,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();

    if (result.errors) {
      console.error("GraphQL errors:", result.errors);
      return { success: false, errors: result.errors };
    }

    const data = result.data?.samples;

    console.log("Samples retrieved successfully:", data);
    return { success: true, samples: data };
  } catch (error) {
    console.error("Error fetching group samples:", error);
    return { success: false, error: error.message };
  }
}

async function updateSampleMetadata(samplePuid, metadata) {
  try {
    const response = await fetch(graphQLUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        query: UPDATE_SAMPLE_METADATA_MUTATION,
        variables: {
          samplePuid,
          metadata,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();

    if (result.errors) {
      console.error("GraphQL errors:", result.errors);
      return { success: false, errors: result.errors };
    }

    const data = result.data?.updateSampleMetadata;

    if (data?.errors && data.errors.length > 0) {
      console.error("Mutation errors:", data.errors);
      return { success: false, errors: data.errors };
    }

    console.log("Sample metadata updated successfully:", data.sample);
    return { success: true, sample: data.sample, status: data.status };
  } catch (error) {
    console.error("Error updating sample metadata:", error);
    return { success: false, error: error.message };
  }
}

// Listen for messages from the main thread
self.onmessage = async function (e) {
  console.log("Worker received:", e.data);
  const { groupId, sampleNameOrPuid, metadata } = e.data;
  let samplePuid;

  try {
    // Verify the sample exists within the group
    if (groupId) {
      const samplesResult = await groupSamples(groupId, {
        name_or_puid_cont: sampleNameOrPuid,
      });

      if (samplesResult.samples.totalCount === 1) {
        samplePuid = samplesResult.samples.nodes[0].puid;
      }

      console.log("Group samples result:", samplesResult);
    } else {
      //TODO: Query project for sample
    }

    // Update the sample metadata
    if (samplePuid && metadata) {
      const metadataResult = await updateSampleMetadata(samplePuid, metadata);
      console.log("Metadata update result:", metadataResult);

      self.postMessage({
        success: metadataResult.success,
        sample: metadataResult.sample,
        status: metadataResult.status,
        errors: metadataResult.errors,
      });
    } else {
      self.postMessage({
        success: false,
        error: `Could not find sample '${sampleNameOrPuid}'`,
      });
    }
  } catch (error) {
    console.error("Worker error:", error);
    self.postMessage({
      success: false,
      error: error.message,
    });
  }
};
