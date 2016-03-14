{SelectListView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
fs = require 'fs-plus'
utils = require './utils'

ToolchainDownloadView = require './toolchain-download-view'

currentDevice = null
deviceList = []           
sep = null

module.exports =
class DeviceSelectView extends SelectListView  
  btnDevSelect: null
  
  initialize: (btnDevSel) ->
    super
    subscriptions = new CompositeDisposable
    subscriptions.add atom.commands.add 'atom-workspace', 
                    'coxide:checkToolchain': => @checkToolchain()
    
    sep = utils.getSeperator()
    @reloadDevList()
    @btnDevSelect = btnDevSel
    @loadDevice()
    @addClass('grammar-selector')
    @list.addClass('mark-active')

  destroy: ->
    @cancel()

  viewForItem: (device) ->
    element = document.createElement('li')
    element.classList.add('active') if device is currentDevice
    element.textContent = device.libName
    element
  
  getFilterKey: ->
    'libName'
  
  cancelled: ->
    @panel?.destroy()
    @panel = null
    @editor = null

  confirmed: (device) ->
    if @writeDevModel(device) is false
      return
    currentDevice = device
    @btnDevSelect.text device.libName
    @cancel()
    
  reloadDevList: ->
    deviceList = atom.config.get('coxide.libVersions')
    for i in [0...deviceList.length]
      if deviceList[i].libType == "builder"
        deviceList.splice(i, 1)
        break

  writeDevModel: (device) ->
    currentProjPath = atom.project.getPaths()[0]
    jsonFilePath = currentProjPath + sep + '.atom-build.json'
    if fs.isFileSync(jsonFilePath) is false 
      alert 'Error : The current project doesn\'t have .atom-build.json file'
      return false

    try 
      jsonData = JSON.parse(fs.readFileSync(jsonFilePath).toString())
      jsonData.args = [ device.libType ]
      fs.writeFileSync(jsonFilePath, JSON.stringify(jsonData, null, ' '))
    catch e
      alert 'Error : Invalid .atom-build.json file.'
      return false
      
    if @_checkToolchain(device.libType) is false
      @_notiDownloadToolchain(device.libName, device.libToolchain, @_doDownloadToolchain)
    return true
    
  _getDeviceByName: (name) ->
    for dev in deviceList
      if name == dev.libName
        return dev
    return null
  
  _getDeviceByType: (type) ->
    for dev in deviceList
      if type == dev.libType
        return dev
    return null
  
  loadDevice: ->
    if atom.project.getPaths()[0] is undefined
      return

    currentProjPath = atom.project.getPaths()[0]  
    jsonFilePath = currentProjPath + sep + '.atom-build.json'

    try 
      jsonData = JSON.parse(fs.readFileSync(jsonFilePath).toString()) 
      if jsonData.args.length > 0
        currentDevice = @_getDeviceByType(jsonData.args[0])
        currentDevice.libToolchain = @_whatToolchain(currentDevice.libType)
        @populateList()
        if currentDevice isnt null
          @btnDevSelect.text currentDevice.libName
          if @_checkToolchain(currentDevice.libType) is false
            @_notiDownloadToolchain(currentDevice.libName, currentDevice.libToolchain, @_doDownloadToolchain)
        else  
          @btnDevSelect.text 'Not support currently'
      else
        @btnDevSelect.text 'Select Your Device'
    catch e
      alert 'Error : Invalid .atom-build.json file.'

  clearDevice: ->
    currentDevice = null
    @populateList()
    @btnDevSelect.text 'Select Your Device'
  
  _whatToolchain: (libType) ->
    libVersions = atom.config.get('coxide.libVersions')
    for i in [0...libVersions.length]
      if libVersions[i].libType == libType
        return libVersions[i].libToolchain
    
  # Check if currnetLibType has an installed toolchain.
  _checkToolchain: (currentLibType) ->
    targetToolChain = @_whatToolchain(currentLibType)
    toolChainList = atom.config.get('coxide.toolchains')
    for i in [0...toolChainList.length]
      if toolChainList[i] == targetToolChain
        return true
    return false

  # This function is requested from build module.
  checkToolchain: ->
    if @_checkToolchain(currentDevice.libType) is false
      @_notiDownloadToolchain(currentDevice.libName, currentDevice.libToolchain, @_doDownloadToolchain)
  
  _notiDownloadToolchain: (libName, libToolchain, doDownload) ->
    noti = atom.notifications.addInfo "["+libName+"] Toolchain download is required!",
              dismissable: true,
              buttons: [{
                text: 'Download'
                className: 'btn-downloadDo'
                onDidClick: -> 
                  noti.dismiss()
                  doDownload(libToolchain)
              }]
  
  _doDownloadToolchain: (libToolchain) ->
    toolchainDownloadView = new ToolchainDownloadView(libToolchain)
    downloadPanel = atom.workspace.addModalPanel(item: toolchainDownloadView.element, visible: true)
    toolchainDownloadView.setPanel(downloadPanel)
    toolchainDownloadView.doDownload()
  
  attach: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @focusFilterEditor()

  toggle: ->
    if @panel?
      @cancel()
    else
      @setItems(deviceList)
      @attach()

