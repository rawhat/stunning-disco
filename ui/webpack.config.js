module.exports = {
  entry: './index.jsx',
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
