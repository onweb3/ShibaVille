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
  resolve: {
    extensions: [".js"],
  },
  output: {
    filename: "game.js",
  },
};
