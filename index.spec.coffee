gulp= require 'gulp'
jsfy= require './'
fs= require 'fs'

describe 'gulp-jsfy',->
  css= 'fixtures/second.css'
  now= Date.now()
  content= """
    html,body{
      height:100%;
    }
    body{
      background:url("./second.png") no-repeat center center;
    }
    body:before{
      content:"#{now}";
    }
    body:after{
      content:"#{now}";
      display:block;
      height:4em;
      background:url(http://berabou.me/bower_components/vectorizer/images/ootani_oniji_1x.png);
    }
  """

  beforeEach ->
    try
      fs.writeFileSync css,content
      fs.unlinkSync "#{css}.js" if fs.existsSync "#{css}.js"

  it 'only jsfy for .css',(done)->
    gulp.src 'fixtures/*'
      .pipe jsfy()
      .pipe gulp.dest 'fixtures'
      .on 'end',()->
        jsfied= fs.readFileSync("#{css}.js").toString()

        # toMatch not working. https://github.com/jasmine/jasmine/issues/738
        expect(jsfied.indexOf(encodeURIComponent(content))).toBeTruthy()
        
        done()

  it 'replace url() to dataurl',(done)->
    gulp.src 'fixtures/*'
      .pipe jsfy
        dataurl:true
        ignoreURL:false
      .pipe gulp.dest 'fixtures'
      .on 'end',()->
        jsfied= fs.readFileSync("#{css}.js").toString()

        expect(jsfied).toMatch encodeURIComponent 'data:image/png'
        
        done()
        
  it 'ignore url(http[s]:)',(done)->
    gulp.src 'fixtures/*'
      .pipe jsfy
        dataurl:true
        ignoreURL:true
      .pipe gulp.dest 'fixtures'
      .on 'end',()->
        jsfied= fs.readFileSync("#{css}.js").toString()

        expect(jsfied).toMatch encodeURIComponent 'ootani_oniji_1x'
        
        done()

  it 'wrap all selector into .filename{}',(done)->
    gulp.src 'fixtures/*'
      .pipe jsfy
        dataurl:true
        ignoreURL:true
        wrapClassName:'test_'
      .pipe gulp.dest 'fixtures'
      .on 'end',()->
        jsfied= fs.readFileSync("#{css}.js").toString()

        expect(jsfied).toMatch encodeURIComponent '.test_second'
        
        done()