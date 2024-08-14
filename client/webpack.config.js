const CopyPlugin = require("copy-webpack-plugin");
const path = require("path");

module.exports = {
  mode: "development",
  entry: "./src/entry.js",
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
      },
    ],
  },
  plugins: [
    new CopyPlugin({
      patterns: [
        { from: path.resolve("src/index.html"), to: path.resolve("dist") },
        {
          from: path.resolve("public/main.css"),
          to: path.resolve("dist/public"),
        },
      ],
    }),
  ],
  resolve: {
    extensions: [".js"],
  },
  output: {
    filename: "game.js",
  },
};
