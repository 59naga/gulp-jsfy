gulp= require 'gulp'
gulp.task 'default',->
  gulp.start 'test'
  gulp.watch '*.coffee',['test']

gulp.task 'test',->
  gulp.src '*.spec.coffee'
    .pipe require('gulp-jasmine')
      timeout:3000
      verbose:true
      # includeStackTrace:true