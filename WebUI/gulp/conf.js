/**
 *  This file contains the variables used in other gulp files
 *  which defines tasks
 *  By design, we only put there very generic config values
 *  which are used in several places to keep good readability
 *  of the tasks
 */

var gutil = require('gulp-util');

/**
 *  The main paths of your project handle these with care
 */
exports.paths = {
  src: 'src',
  dist: 'dist',
  tmp: '.tmp',
  e2e: 'e2e'
};

/**
 *  Wiredep is the lib which inject bower dependencies in your project
 *  Mainly used to inject script tags in the index.html but also used
 *  to inject css preprocessor deps and js files in karma
 */
exports.wiredep = {
  exclude: [
    "bower_components/dialogs/dist/dialogs-default-translations.js",
    "bower_components/bootstrap/dist/css/bootstrap.css",
    "bower_components/bootstrap-datepicker/dist/css/bootstrap-datepicker.css",
    "bower_components/bootstrap-datepicker/dist/css/bootstrap-datepicker3.css",
    "bower_components/bootstrap-select/dist/css/bootstrap-select.css",
    "bower_components/bootstrap-switch/dist/css/bootstrap3/bootstrap-switch.css",
    "bower_components/bootstrap-treeview/dist/bootstrap-treeview.min.css",
    "bower_components/c3/c3.css",
    "bower_components/datatables/media/css/jquery.dataTables.css",
    "bower_components/datatables-colreorder/css/dataTables.colReorder.css",
    "bower_components/datatables-colvis/css/dataTables.colVis.css",
    "bower_components/font-awesome/css/font-awesome.css",
    "bower_components/google-code-prettify/bin/prettify.min.css"
  ],
  directory: 'bower_components'
};

/**
 *  Common implementation for an error handler of a Gulp plugin
 */
exports.errorHandler = function(title) {
  'use strict';

  return function(err) {
    gutil.log(gutil.colors.red('[' + title + ']'), err.toString());
    this.emit('end');
  };
};
