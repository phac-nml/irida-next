module.exports = {
  ci: {
    collect: {
      url: ["http://localhost:3000/"],
      startServerCommand: "bin/rails server",
    },
    upload: {
      target: "temporary-public-storage",
    },
  },
};
