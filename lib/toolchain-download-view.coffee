{$, View} = require 'space-pen'
request = require 'request'
fs = require 'fs-plus'
rmdir = require 'rimraf'
unzip = require 'unzip'
wrench = require 'wrench'
utils = require './utils'

sep = null

module.exports =
class ToolchainDownloadView extends View
  myPanel = null
  response = null
  zipFile = null
  targetToolchain = null
  totalSize = null
  totalSizeMB = null
  dotsSeed = 0
  dotsLoop = [
    '.',
    '. .',
    '. . .',
    '. . . .',
    '. . . . .',
    '. . . . . .'
  ]
  
  @content: (toolchain) ->
    @div class: 'coxide', =>
      @h1 class: 'font-size22', =>
        @text "Installing Toolchain..."
      @hr
      @h1 =>
        @span class: 'icon icon-plus'
        @label toolchain
      @h1 =>
        @progress style: 'width: 90%;', outlet: 'progBar', value:0
        @label style: 'margin-left: 10px;', outlet: 'lbPercent', class: 'pull-right', '0%'        
      @h2 =>
        @label style: 'margin-left: 10px;', outlet: 'lbShowSize'
        @label style: 'margin-left: 10px;', outlet: 'lbStatus','Downloading'
        @label outlet: 'lbDots' , '.'
      @button outlet: 'btnCancel', class: 'btn btn-size15 pull-right', 'Cancel'
      
  initialize: (toolchain) ->
    @targetToolchain = toolchain
    @btnCancel.on 'click', => 
      if @myPanel isnt null
        @myPanel.hide()
      if @response isnt null
        @response.abort()

  serialize: ->

  destroy: ->
    @element.remove()
  
  setPanel: (panel) ->
    @myPanel = panel
    
  doDownload: ->
    installPath = utils.getInstallPath()
    serverURL = atom.config.get('coxide.serverURL')
    platform = utils.getPlatform()
    url = serverURL + '/lib-toolchain-download/' + platform + '/' + @targetToolchain
    
    sep = utils.getSeperator()
    filePath = installPath + sep + "cox-sdk" + sep + "tools" + sep
    fileName = "temp.zip"

    count = 0
    seq = null
    obj = this
    
    file = fs.createWriteStream(filePath + fileName)
    @response = request.get url
    @response.pipe file
    
    @response.on 'data', (chunk) =>
      # bad code for exception..
      if chunk.toString() == "-2" || chunk.toString() == "-1"
        alert "Server Error. Please retry later."
        @response.abort()
        return
      count = count + chunk.length
      # 1% is for unzipping
      percent = parseInt(count * 99 / totalSize)
      @lbPercent.text(percent + "%")
      @lbShowSize.text('('+parseInt(count/1024/1024)+'/'+totalSizeMB+'MB)')
      @progBar.val(parseInt(percent))
      
    @response.on 'response', (data) =>
      totalSize = data.headers[ 'content-length' ]
      totalSize = parseInt(totalSize)
      totalSizeMB = parseInt(totalSize/1024/1024)
      @progBar.attr('max', 100)
      seq = setInterval -> 
        obj.lbDots.text(dotsLoop[(dotsSeed%dotsLoop.length)])
        dotsSeed = dotsSeed + 1
      , 500

    file.on 'finish', =>
      file.close()
      if totalSize != count
        clearInterval(seq)
        alert 'Download has been canceled.'
        fs.unlink(filePath + fileName)
      else
        @lbStatus.text('Unzipping')
        @btnCancel.attr('disabled', true)
        @btnCancel.text('Wait..')
        @zipFile = fs.createReadStream(filePath+fileName)
          .pipe(unzip.Extract({ path: filePath }));

        @zipFile.on 'close', =>
          fs.unlink(filePath + fileName)
          if platform == 'linux' || platform == 'darwin'
            wrench.chmodSyncRecursive(filePath+@targetToolchain, 0o755)
          clearInterval(seq)
          @progBar.val(100)
          @lbPercent.text('100%')
          @lbDots.text('!')
          @lbStatus.text('Completed')
          @btnCancel.attr('disabled', false)
          @btnCancel.text('Close')
          installedToolchains = atom.config.get('coxide.toolchains')
          installedToolchains.push(@targetToolchain)
          atom.config.set('coxide.toolchains', installedToolchains)
          alert 'Install has been completed!'
      
    file.on 'error', =>
      alert 'Download has been failed. Please retry again.'
