gulp= require 'gulp'
jsfy= require '../src'
fs= require 'fs'

createFixture= ->
  """
    body{
      height:100%;
      background:url("./second.png?#iefix") no-repeat center center;
    }
    body:before{
      content:"←";
    }
    body:after{
      content:"→";
      display:block;
      height:4em;
      background:url('http://berabou.me/bower_components/vectorizer/images/ootani_oniji_1x.png');
    }
    article{
      background:url("./second.png?3ocs8m") no-repeat center center;
    }
    section{
      background:url("./second.png#3ocs8m") no-repeat center center;
    }
  """

describe 'gulp-jsfy',->
  fixture= __dirname+'/fixtures/second.black.css'

  contents= createFixture()
  beforeEach ->
    try
      fs.writeFileSync fixture,contents
  afterEach ->
    try
      fs.unlinkSync "#{fixture}.js" if fs.existsSync "#{fixture}.js"

  it 'only jsfy for .css',(done)->
    options= {}

    gulp.src __dirname+'/fixtures/*'
      .pipe jsfy options
      .pipe gulp.dest __dirname+'/fixtures'
      .on 'end',->
        js= fs.readFileSync("#{fixture}.js").toString()
        expect(js.toString()).not.toEqual(contents)
        done()

  it 'replace url() to dataurl',(done)->
    options=
      dataurl:true

    gulp.src __dirname+'/fixtures/*'
      .pipe jsfy options
      .pipe gulp.dest __dirname+'/fixtures'
      .on 'end',->
        js= fs.readFileSync("#{fixture}.js").toString()
        expect(jsfy.cssfy js).toMatch('data:image/png;base64')
        done()
        
  it 'ignore url(http[s]:)',(done)->
    options=
      dataurl:true
      ignoreURL:true
      
    gulp.src __dirname+'/fixtures/*'
      .pipe jsfy options
      .pipe gulp.dest __dirname+'/fixtures'
      .on 'end',->
        js= fs.readFileSync("#{fixture}.js").toString()
        expect(jsfy.cssfy js).toMatch('berabou.me')
        done()

  it 'wrap all selector into .file_name{}',(done)->
    options=
      dataurl:true
      wrapInClass:'test_'

    gulp.src __dirname+'/fixtures/*'
      .pipe jsfy options
      .pipe gulp.dest __dirname+'/fixtures'
      .on 'end',->
        js= fs.readFileSync("#{fixture}.js").toString()
        expect(jsfy.cssfy js).toMatch('.second_black')
        done()
