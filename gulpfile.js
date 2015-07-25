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
var request = require('request');
var watchify = require('watchify');
var watch = require('gulp-watch');

// inspired by
// https://github.com/gulpjs/gulp/blob/master/docs/recipes/fast-browserify-builds-with-watchify.md
// add custom browserify options here
var customOpts = {
  extensions: [ '.coffee', '.js', '.csv' ],
  debug: true
};
function basenameToEntries(basename) { return [ './js/' + basename + '.coffee' ]; }
function watchJs(basename) {
  var opts = assign({ entries: basenameToEntries(basename) }, watchify.args, customOpts);
  var b = watchify(browserify(opts));
  b.transform(require('coffeeify'));
  b.transform(require('brfs'));
  b.on('update', function() { return runBrowserify(b, basename); }); // on any dep update, runs the bundler
  b.on('log', gutil.log); // output build logs to terminal
  return runBrowserify(b, basename);
}
function compileJsOnce(basename) {
  var opts = assign({ entries: basenameToEntries(basename) }, customOpts);
  var b = browserify(opts);
  b.transform(require('coffeeify'));
  b.transform(require('brfs'));
  b.transform(require('uglifyify'));
  b.on('log', gutil.log); // output build logs to terminal
  return runBrowserify(b, basename);
}
function runBrowserify(b, basename) {
  return b.bundle()
    // log errors if they happen
    .on('error', gutil.log.bind(gutil, 'Browserify Error'))
    .pipe(source(basename + '.js'))
    // optional, remove if you don't need to buffer file contents
    .pipe(buffer())
    // optional, remove if you dont want sourcemaps
    .pipe(sourcemaps.init({loadMaps: true})) // loads map from browserify file
       // Add transformation tasks to the pipeline here.
    .pipe(sourcemaps.write('./')) // writes .map file
    .pipe(gulp.dest('./dist'));
}

gulp.task('policies-csv', function() {
  var url = 'https://docs.google.com/spreadsheets/d/1pwNglbBgZG9-x_gEypBBFeL-gahBas0ZSuHNoOVpn8c/pub?gid=1636922037&single=true&output=csv';
  request(url)
    .pipe(source('policies.csv'))
    .pipe(gulp.dest('./data'));
});

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

gulp.task('js', [ 'js-en', 'js-fr' ]);
gulp.task('watch-js', [ 'watch-js-en', 'watch-js-fr' ]);

gulp.task('js-en', function() { return compileJsOnce('index.en'); });
gulp.task('js-fr', function() { return compileJsOnce('index.fr'); });
gulp.task('watch-js-en', function() { return watchJs('index.en'); });
gulp.task('watch-js-fr', function() { return watchJs('index.fr'); });

gulp.task('default', [ 'less', 'js' ]);
gulp.task('watch', [ 'watch-less', 'watch-js' ]);
