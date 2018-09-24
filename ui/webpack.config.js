//const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin')

module.exports = {
  devtool: 'source-map',
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
        use: [{
          loader: 'babel-loader'
        }, {
          loader: 'ts-loader'
        }]
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      }, {
        test: /\.js$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'babel-loader',
          }
        ]
      }
    ]
  },
  plugins: [
    //new MonacoWebpackPlugin()
  ],
  resolve: {
    extensions: ['.ts', '.tsx', '.js']
  },
  devServer: {
    host: '0.0.0.0',
    port: '8080',
  }
}
