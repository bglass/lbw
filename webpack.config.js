const url = "lbw"    // change this to the url specified in the uibuilder node
const src = './uibuilder/' + url + '/src'


var webpack = require('webpack')
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const path = require('path');

var HTMLWebpackPluginConf = new HtmlWebpackPlugin({
  template: __dirname + '/uibuilder/' + url + '/src/html/index.pug',
  filename: 'index.html'
});

var CopyWebpackPluginConf = new CopyWebpackPlugin([
  { from: './uibuilder/' + url + '/src/manifest.json' }
]);

var UglifyJSPluginConf = new UglifyJSPlugin({
  uglifyOptions: {
    compress: {
      warnings: false,
    },
    output: {
      comments: false
    },
  }
});

var webpackJQueryPluginConf = new webpack.ProvidePlugin({
  $: "jquery",
  jQuery: "jquery"
});

module.exports = {
  entry: [
    src + '/js/main.coffee',
    'normalize.css'
  ],
  output: {
      path: path.resolve(__dirname, 'uibuilder/' + url + '/dist'),
      filename: 'bundle.min.js'
  },
  plugins: [
    webpackJQueryPluginConf,
    UglifyJSPluginConf,
    HTMLWebpackPluginConf,
    CopyWebpackPluginConf
  ],
  module: {
    rules: [
      { test: /\.coffee$/,
        include: [
          path.resolve(__dirname, src + '/js')
        ],
        use: [ 'coffee-loader' ]
      },
      { test: /.pug$/,
        include: path.resolve(__dirname, src + '/html'),
        use: { loader: 'pug-loader',
                query: {} // Can be empty
        }
      },
      {
        // Note, if you decide to include babel-loader then, for some reason, this
        // has to go after babel-loader or 'this' is changed to undefined.
        // don't understand why, I expected to have to do it the other way round.
        // This bit is required because uibuilderfe expects 'this' to be set to window
        test: /uibuilderfe.js$/,
        use: "imports-loader?this=>window"
      },
      {
        test: /\.css$/,
        exclude: /node_modules/,
        loader: 'style-loader!css-loader'
      },
      {
        // this is necessary as normally we do not want css from node modules
        // so for normalize.css have to include an explicit rule
        test: /normalize.css$/,
        loader: 'style-loader!css-loader'
      }
    ]
  }
};
