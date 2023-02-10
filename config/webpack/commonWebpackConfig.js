// The source code including full typescript support is available at:
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/config/webpack/commonWebpackConfig.js

const ForkTsCheckerWebpackPlugin = require("fork-ts-checker-webpack-plugin");

// Common configuration applying to client and server configuration
const {
  webpackConfig: baseClientWebpackConfig,
  merge,
} = require("shakapacker");

const commonOptions = {
  resolve: {
    extensions: [".css", ".ts", ".tsx"],
  },
  plugins: [new ForkTsCheckerWebpackPlugin()],
};

// Copy the object using merge b/c the baseClientWebpackConfig and commonOptions are mutable globals
const commonWebpackConfig = () =>
  merge({}, baseClientWebpackConfig, commonOptions);

module.exports = commonWebpackConfig;
