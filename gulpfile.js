'use strict';

var assign = require('lodash.assign');
var browserify = require('browserify');
var buffer = require('vinyl-buffer');
var gulp = require('gulp');
var gutil = require('gulp-util');
var less = require('gulp-less');
var plumber = require('gulp-plumber');
var sourcemaps = require('gulp-sourcemaps');
var source = require('vinyl-source-stream');
var watchify = require('watchify');
var watch = require('gulp-watch');

// https://github.com/gulpjs/gulp/blob/master/docs/recipes/fast-browserify-builds-with-watchify.md
// add custom browserify options here
var customOpts = {
  entries: ['./js/index.coffee'],
  extensions: [ '.coffee', '.js', '.csv' ],
  debug: true
};
var opts = assign({}, watchify.args, customOpts);
var b = watchify(browserify(opts)); 
// add transformations here
b.transform(require('coffeeify'));
b.transform(require('node-csvify'));

gulp.task('js', bundle); // so you can run `gulp js` to build the file
b.on('update', bundle); // on any dep update, runs the bundler
b.on('log', gutil.log); // output build logs to terminal

function bundle() {
  return b.bundle()
    // log errors if they happen
    .on('error', gutil.log.bind(gutil, 'Browserify Error'))
    .pipe(source('index.js'))
    // optional, remove if you don't need to buffer file contents
    .pipe(buffer())
    // optional, remove if you dont want sourcemaps
    .pipe(sourcemaps.init({loadMaps: true})) // loads map from browserify file
       // Add transformation tasks to the pipeline here.
    .pipe(sourcemaps.write('./')) // writes .map file
    .pipe(gulp.dest('./dist'));
}

gulp.task('less', function() {
  return gulp.src('./less/index.less')
    .pipe(plumber({
      handleError: function(err) {
        console.warn(err);
        this.emit('end');
      }
    }))
    .pipe(less({}))
    .pipe(gulp.dest('./dist'));
});

gulp.task('watch-less', [ 'less' ], function() {
  gulp.watch([ './less/**/*' ], [ 'less' ]);
});

gulp.task('default', [ 'watch-less', 'js' ]);
