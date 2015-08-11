{SelectListView} = require 'atom-space-pen-views'

currentDevice = ''
deviceList = ['Atmel SAMR21 Xplained pro',
              'Device B',
              'Device C',
              'Device D',
              'Device E',
              'Device F',
              'Device G',
              'Device H',
              'Device I',
              'Device J',
              'Device K']

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
    element.textContent = device
    element

  cancelled: ->
    @panel?.destroy()
    @panel = null
    @editor = null

  confirmed: (device) ->
    currentDevice = device
    @btnDevSelect.text device
    @cancel()
    
  attach: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @focusFilterEditor()

  toggle: ->
    if @panel?
      @cancel()
    else if @editor = atom.workspace.getActiveTextEditor()
      @setItems(deviceList)
      @attach()
      