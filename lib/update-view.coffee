{$, View} = require 'space-pen'
request = require 'request'
fs = require 'fs-plus'
rmdir = require 'rimraf'
unzip = require 'unzip'

module.exports =
class UpdateView extends View
  myPanel = null
  @content: (upList) ->
    @div class: 'coxide', =>
      @h1 class: 'font-size22', =>
        @text "Updating Libraries..."
      @div outlet: 'updateListDiv', =>
        for i in [0...upList.length]
          @h1 =>
            @span class: 'icon icon-plus'
            @label upList[i].libType 
            @text "   [" + upList[i].libOldVer + "->" 
            @span upList[i].libNewVer
            @text "]"
            @span class: 'pull-right', =>
              @progress class: 'inline-block', max: 100, value: 0
      
      @button outlet: 'btnUpdateClose', class: 'btn btn-size15 pull-right', 'Close'
      
  initialize: () ->
    @btnUpdateClose.on 'click', => 
      if @myPanel isnt null
        @myPanel.hide()
    
    @doUpdate()

  serialize: ->

  destroy: ->
    @element.remove()
  
  setPanel: (panel) ->
    @myPanel = panel
  
  doUpdate: ->
    count = @updateListDiv.children().length
    libVersions = atom.config.get('coxide.libVersions')
    installPath = atom.config.get('coxide.installPath')
    serverURL = atom.config.get('coxide.serverURL')
    url = serverURL + '/lib-download/'
    
    for item in @updateListDiv.children()  
      libType = $(item).find('label').text()
      libNewVer = $(item).find('span').text()
      prog = $(item).find('progress')[0]
      filePath = installPath + "\\NOL.A\\cox-sdk\\"
      fileName = libType + ".zip"
      
      do (url, prog, filePath, fileName, libType, libNewVer) ->
        extractPath = filePath + libType
        if libType == "builder"
          rmdir.sync filePath + "include"
          rmdir.sync filePath + "make"
          extractPath = filePath
        else
          rmdir.sync filePath + libType
        
        file = fs.createWriteStream(filePath + fileName)
        request.get url + libType 
          .pipe file
        file.on 'finish', =>  
          file.close();
          prog.value = 50
          zipFile = fs.createReadStream(filePath + fileName)
            .pipe(unzip.Extract({ path: extractPath }));
          zipFile.on 'close', =>
            fs.unlink(filePath + fileName) 
            for i in [0...libVersions.length]
              if libVersions[i].libType == libType
                libVersions[i].libVersion = libNewVer
                break                
            prog.value = 100
            
            # count '0' means all is done.
            count = count - 1
            if count == 0 
              atom.config.set('coxide.libVersions', libVersions)
              alert 'Update completed'