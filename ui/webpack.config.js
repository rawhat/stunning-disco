module.exports = {
  entry: './index.tsx',
  output: {
    path: __dirname,
    publicPath: "/",
    filename: "main.js"
  },
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        exclude: /node_modules/,
        use: {
          loader: 'ts-loader'
        }
      }
    ]
  },
  resolve: {
    extensions: ['.ts', '.tsx', '.js']
  },
  devServer: {
    host: '0.0.0.0',
    port: '8080',
  }
}
