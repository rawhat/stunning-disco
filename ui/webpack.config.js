module.exports = {
  entry: './index.js',
  output: {
    path: __dirname,
    publicPath: "/",
    filename: "main.js"
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      }
    ]
  },
  devServer: {
    host: '0.0.0.0',
    port: '8080',
  }
}