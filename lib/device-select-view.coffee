{SelectListView} = require 'atom-space-pen-views'
fs = require 'fs-plus'
utils = require './utils'

currentDevice = null
deviceList = []           
sep = null

module.exports =
class DeviceSelectView extends SelectListView  
  btnDevSelect: null
  
  initialize: (btnDevSel) ->
    super
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
      return true
    catch e
      alert 'Error : Invalid .atom-build.json file.'
      return false
  
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
        @populateList()
        if currentDevice isnt null
          @btnDevSelect.text currentDevice.libName
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

