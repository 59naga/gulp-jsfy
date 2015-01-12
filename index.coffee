through= require 'through'
path= require 'path'

jsfy= (file)->
  filename= path.relative process.cwd(),file.path
  file.path+='.js'
  file.contents= new Buffer """
    (function(){
      var link=document.createElement('link');
      link.setAttribute('data-filename','#{filename}');
      link.setAttribute('rel','stylesheet');
      link.setAttribute('href',"data:text/css;base64,#{encodeURIComponent file.contents.toString('base64')}");
      document.head.appendChild(link);
    })();
  """

  file

fs= require 'fs'
mime= require 'mime'
http= require 'http'
async= require 'async'
replaceToDataURL= (file,callback,options={})->
  css= file.contents.toString()
  # return callback "#{file.path} is jsfied css",css if css.indexOf '(function(){' is 0

  pattern= /url\((?!data:)(.+?)\)/
  pattern= /url\((?!(?:data:|http))(.+?)\)/ if options.ignoreURL is true

  result= null
  async.whilst ()->
    result= css.match pattern
    result isnt null
  ,(next)->
    [match,subpattern]= result

    url= subpattern.replace /"|'/g,''
    if url.indexOf('http') is 0
      mimetype= null

      http.get url,(response)->
        # response.setEncoding 'binary'
        mimetype=  response?.headers?['content-type']

        response.on 'data',(buffer)->
          data= buffer.toString 'base64'
          dataurl= "data:#{mimetype};base64,#{data}"
          css= css.replace subpattern,dataurl

          # console.log buffer,url,"\n",buffer.length

          next null
      .on 'error',(error)-> 
        next error
    else
      filename= path.resolve path.dirname(file.path),url.replace(/(#|\?).+/g,'')
      mimetype= mime.lookup filename

      # console.log filename,url

      fs.readFile filename,(error,buffer)->
        next error if error?

        data= buffer.toString 'base64'
        dataurl= "data:#{mimetype};base64,#{data}"
        css= css.replace subpattern,dataurl

        # console.log buffer,filename,"\n",buffer.length

        next null
  ,(error)->
    callback error,css

module.exports= (options={})->
  queues= []
  through (file)->
    self= this

    do (self,file)=>
      if file.path.substr(-4) isnt '.css'
        queues.push (next)=>
          self.emit 'data',file
          next null
        return

      if options.wrapClassName
        queues.push (next)=>
          css= file.contents.toString()
          className= path.basename file.path,'.css'
          if typeof options.wrapClassName is 'string'
            className= "#{options.wrapClassName}#{className}"

          stylus= require 'stylus'
          stylus.render ".#{className}{ #{css} }",(error,css)=>
            return next error if error?  

            file.contents= new Buffer css

            # passed next queue
            # self.emit 'data',jsfy file
            next null
        
      if options.dataurl isnt true
        queues.push (next)=>
          self.emit 'data',jsfy file
          next null
      else
        queues.push (next)=>
          replaceToDataURL file,(error,css)=>
            next error if error?

            file.contents= new Buffer css

            self.emit 'data',jsfy file
            next null
          ,options
  ,->
    async.each queues,(queue,next)->
      queue (error)-> next error
    ,(error)=>
      throw error if error?

      this.emit 'end'
