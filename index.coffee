through= require 'through'
path= require 'path'

module.exports= ->
  through (file)->
    return if file.contents is null

    if file.path.substr(-4) is '.css'
      stylesheet= encodeURIComponent file.contents.toString()
      filename= path.relative __dirname,file.path
      file.path+='.js'
      file.contents= new Buffer """
        (function(){
          var style=document.createElement('style');
          style.setAttribute('title','#{filename}');
          style.textContent=decodeURIComponent("#{stylesheet}");
          document.head.appendChild(style);
        })();
      """

    this.emit 'data',file
  ,->
    this.emit 'end'
