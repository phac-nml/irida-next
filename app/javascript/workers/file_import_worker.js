// Listen for messages from the main thread
self.onmessage = function (e) {
  console.log("Worker received:", e.data);

  // Perform a calculation (e.g., squaring a number)
  const result = e.data * e.data;

  // Send the result back to the main thread
  self.postMessage(result);
};
