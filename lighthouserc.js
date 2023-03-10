module.exports = {
  ci: {
    collect: {
      url: ["http://localhost:3000/"],
      startServerCommand: "bin/rails server -e production",
    },
    upload: {
      target: "temporary-public-storage",
    },
  },
};
