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

// Function to execute the UpdateSampleMetadata mutation
async function updateSampleMetadata(samplePuid, metadata) {
  try {
    const response = await fetch("/api/graphql", {
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
self.onmessage = function (e) {
  console.log("Worker received:", e.data);
  const { samplePuid, metadata } = e.data;

  if (samplePuid && metadata) {
    // Execute the mutation if sample data is provided
    updateSampleMetadata(samplePuid, metadata).then((result) => {
      self.postMessage(result);
    });
  }
};
