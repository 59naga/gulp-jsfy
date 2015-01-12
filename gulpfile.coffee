gulp= require 'gulp'
gulp.task 'default',->
  gulp.start 'test'
  gulp.watch '*.coffee',['test']

gulp.task 'test',->
  gulp.src '*.spec.coffee'
    .pipe require('gulp-jasmine')
      verbose:true
      timeout:1000
      includeStackTrace:true