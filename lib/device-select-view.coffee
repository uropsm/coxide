{SelectListView} = require 'atom-space-pen-views'
fs = require 'fs-plus'

currentDevice = null
deviceList = [
            {
              name: "Atmel SAMR21 Xplained pro",
              flag: "SAMR21"
            },
            {
              name: "Device A",
              flag: "AAA"
            },
            {
              name: "Device B",
              flag: "BBB"
            },
            {
              name: "Device C",
              flag: "CCC"
            },
            {
              name: "Device D",
              flag: "DDD"
            },
         ]           

module.exports =
class DeviceSelectView extends SelectListView  
  btnDevSelect: null
  
  initialize: (btnDevSel) ->
    super

    @btnDevSelect = btnDevSel
    @addClass('grammar-selector')
    @list.addClass('mark-active')

  destroy: ->
    @cancel()

  viewForItem: (device) ->
    element = document.createElement('li')
    element.classList.add('active') if device is currentDevice
    element.textContent = device.name
    element

  cancelled: ->
    @panel?.destroy()
    @panel = null
    @editor = null

  confirmed: (device) ->
    if @writeDevModel(device) is false
      return
    currentDevice = device
    @btnDevSelect.text device.name
    @cancel()

  writeDevModel: (device) ->
    currentProjPath = atom.project.getPaths()[0]
    jsonFilePath = currentProjPath + '\\.atom-build.json'
    if fs.isFileSync(jsonFilePath) is false 
      alert 'Error : The current project doesn\'t have .atom-build.json file'
      return false
      
    try 
      jsonData = JSON.parse(fs.readFileSync(jsonFilePath).toString())
      jsonData.args = [ device.flag ]
      fs.writeFileSync(jsonFilePath, JSON.stringify(jsonData, null, ' '))
      return true
    catch e
      alert 'Error : Invalied .atom-build.json file.'
      return false
  
  _getDeviceByName: (name) ->
    for dev in deviceList
      if name == dev.name
        return dev
    return null
  
  _getDeviceByFlag: (flag) ->
    for dev in deviceList
      if flag == dev.flag
        return dev
    return null
  
  loadDevice: ->
    currentProjPath = atom.project.getPaths()[0]
    jsonFilePath = currentProjPath + '\\.atom-build.json'

    try 
      jsonData = JSON.parse(fs.readFileSync(jsonFilePath).toString()) 
      currentDevice = @_getDeviceByFlag(jsonData.args[0])
      @populateList()
      if currentDevice isnt null
        @btnDevSelect.text currentDevice.name
      else  
        @btnDevSelect.text 'Select Your Device'
    catch e
      alert 'Error : Invalied .atom-build.json file.'
    
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
