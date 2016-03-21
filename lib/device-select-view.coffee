{SelectListView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
fs = require 'fs-plus'
utils = require './utils'

ToolchainDownloadView = require './toolchain-download-view'

module.exports =
class DeviceSelectView extends SelectListView  
  btnDevSelect: null
  sep: null
  deviceList: []
  curDev: null
  
  initialize: (btnDevSel) ->
    super
    @btnDevSelect = btnDevSel
    @addClass('grammar-selector')
    @list.addClass('mark-active')
    @sep = utils.getSeperator()
    
    @initDevList()
    if atom.project.getPaths()[0] isnt undefined
      @loadDevice()

    subscriptions = new CompositeDisposable
    subscriptions.add atom.commands.add 'atom-workspace', 
                    'coxide:checkToolchain': => @checkToolchain()

  destroy: ->
    @cancel()

  viewForItem: (device) ->
    element = document.createElement('li')
    element.classList.add('active') if device is @curDev
    element.textContent = device.libName
    element
  
  getFilterKey: ->
    'libName'
  
  cancelled: ->
    @panel?.destroy()
    @panel = null
    @editor = null

  confirmed: (device) ->
    if @selectDev(device) is false
      return
    @curDev = device
    @btnDevSelect.text device.libName
    @cancel()
  
  attach: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @focusFilterEditor()

  toggle: ->
    if @panel?
      @cancel()
    else
      @setItems(@deviceList)
      @attach()

  initDevList: ->
    @deviceList = atom.config.get('coxide.libVersions')
    for i in [0...@deviceList.length]
      if @deviceList[i].libType == "builder"
        @deviceList.splice(i, 1)
        break

  loadDevice: ->
    currentProjPath = atom.project.getPaths()[0]  
    jsonFilePath = currentProjPath + @sep + '.atom-build.json'
    try 
      jsonData = JSON.parse(fs.readFileSync(jsonFilePath).toString()) 
      if jsonData.args.length > 0
        @curDev = @_getDeviceByType(jsonData.args[0])
        @populateList()
        if @curDev isnt null
          @btnDevSelect.text @curDev.libName
          @checkToolchain()
        else  
          @btnDevSelect.text 'Not support currently'
      else
        @btnDevSelect.text 'Select Your Device'
    catch e
      alert 'Error : Invalid .atom-build.json file.'

  clearDevice: ->
    @curDev = null
    @populateList()
    @btnDevSelect.text 'Select Your Device'
    
  selectDev: (device) ->
    currentProjPath = atom.project.getPaths()[0]
    jsonFilePath = currentProjPath + @sep + '.atom-build.json'
    if fs.isFileSync(jsonFilePath) is false 
      alert 'Error : The current project doesn\'t have .atom-build.json file'
      return false

    try 
      jsonData = JSON.parse(fs.readFileSync(jsonFilePath).toString())
      jsonData.args = [ device.libType ]
      fs.writeFileSync(jsonFilePath, JSON.stringify(jsonData, null, ' '))
    catch e
      alert 'Error : .atom-build.json modification failure.'
      return false

    if @hasToolchain(device.libToolchain) is false
      @notiDownloadToolchain(device.libName, device.libToolchain, @doDownloadToolchain)
    return true

  hasToolchain: (toolchain) ->
    toolChainList = atom.config.get('coxide.toolchains')
    for i in [0...toolChainList.length]
      if toolChainList[i] == toolchain
        return true
    return false

  # This function is also requested from build module.
  checkToolchain: ->
    if @curDev isnt null
      if @hasToolchain(@curDev.libToolchain) is false
        @notiDownloadToolchain(@curDev.libName, @curDev.libToolchain, @doDownloadToolchain)
  
  notiDownloadToolchain: (libName, libToolchain, doDownload) ->
    noti = atom.notifications.addInfo "["+libName+"] Toolchain download is required!",
              dismissable: true,
              buttons: [{
                text: 'Download'
                className: 'btn-downloadDo'
                onDidClick: -> 
                  noti.dismiss()
                  doDownload(libToolchain)
              }]
  
  doDownloadToolchain: (libToolchain) ->
    toolchainDownloadView = new ToolchainDownloadView(libToolchain)
    downloadPanel = atom.workspace.addModalPanel(item: toolchainDownloadView.element, visible: true)
    toolchainDownloadView.setPanel(downloadPanel)
    toolchainDownloadView.doDownload()
  
  _getDeviceByType: (type) ->
    for dev in @deviceList
      if type == dev.libType
        return dev
    return null