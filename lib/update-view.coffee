{$, View} = require 'space-pen'
request = require 'request'
fs = require 'fs-plus'
rmdir = require 'rimraf'
unzip = require 'unzip'

module.exports =
class UpdateView extends View
  myPanel = null
  updateCount = null
  updateList = null
  @content: (upList) ->
    @div class: 'coxide', =>
      @h1 class: 'font-size22', =>
        @text "Updating Libraries..."
      @div class: 'font-size12', outlet: 'updateListDiv', =>
        for i in [0...upList.length]
          @h1 =>
            @span class: 'icon icon-plus'
            if upList[i].libName.length > 16
              @label outlet: 'libName'+i, upList[i].libName.substring(0, 16) + "..."
            else
              @label outlet: 'libName'+i, upList[i].libName
            @label outlet: 'libType'+i, class: 'hidden', upList[i].libType
            if upList[i].libOldVer is "NEW"
              @text "   [ New " 
              @label outlet: 'libNewVer'+i, upList[i].libNewVer
            else if upList[i].libNewVer is "DELETE"
              @text "   [ Delete " 
              @label upList[i].libOldVer
              @label outlet: 'libNewVer'+i, ""
            else
              @text "   [ " + upList[i].libOldVer + "->" 
              @label outlet: 'libNewVer'+i, upList[i].libNewVer
            @text " ]"
            @span class: 'pull-right', =>
              @progress outlet: 'prog'+i, class: 'inline-block', max: 100, value: 0
      
      @button outlet: 'btnUpdateClose', class: 'btn btn-size15 pull-right', 'Close'
      
  initialize: (upList) ->
    @updateCount = upList.length
    @updateList = upList
    @btnUpdateClose.on 'click', => 
      if @myPanel isnt null
        @myPanel.hide()

  serialize: ->

  destroy: ->
    @element.remove()
  
  setPanel: (panel) ->
    @myPanel = panel

  doUpdate: ->
    count = @updateCount
    libVersions = atom.config.get('coxide.libVersions')
    installPath = atom.config.get('coxide.installPath')
    serverURL = atom.config.get('coxide.serverURL')
    privateKey = atom.config.get('coxide.privateKey')
    url = null
    if typeof privateKey isnt 'undefined' and privateKey isnt ''
      url = serverURL + '/lib-download/' + privateKey + '/'
    else
      url = serverURL + '/lib-download/'
    
    for i in [0...@updateCount]
      libName = @updateList[i].libName
      libType = @updateList[i].libType
      libNewVer = @updateList[i].libNewVer
      prog = this['prog'+i]
      filePath = installPath + "\\NOL.A\\cox-sdk\\"
      fileName = libType + ".zip"
      
      do (url, prog, filePath, fileName, libName, libType, libNewVer) ->
        if libNewVer is "DELETE"
          for j in [0...libVersions.length]
            if libVersions[j].libType == libType
              libVersions.splice(j,1)
              prog.val(100)
              count = count - 1
              if count == 0 
                atom.config.set('coxide.libVersions', libVersions)
                alert 'Update completed. IDE will be restarted automatically.'
                atom.reload()
                return
              break
        else
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
            prog.val(50)
            zipFile = fs.createReadStream(filePath + fileName)
              .pipe(unzip.Extract({ path: extractPath }));
            zipFile.on 'close', =>
              fs.unlink(filePath + fileName) 
              for j in [0...libVersions.length]
                if libVersions[j].libType == libType
                  libVersions[j].libVersion = libNewVer
                  break
                if j == libVersions.length-1
                  libVersions.push({ libName: libName, \
                                     libType: libType, \
                                     libVersion: libNewVer })
              prog.val(100)
              
              # count '0' means all is done.
              count = count - 1
              if count == 0 
                atom.config.set('coxide.libVersions', libVersions)
                alert 'Update completed. IDE will be restarted automatically.'
                atom.reload()