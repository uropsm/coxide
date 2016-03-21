{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'
request = require 'request'

module.exports =
class SetPrivateView extends View 
  modalPanel: null
  privateKey: null
  
  @content: ->
    @div class: 'coxide', =>
      @h1 class: 'icon icon-key', =>
        @text "Setting Private Key"
        @span class: 'pull-right icon icon-x', outlet: 'btnCancel'
      
      @h2 "Private Key :"
      @subview 'edtPrvKey', new TextEditorView(mini: true, placeholderText: 'Empty')

      @h2 ""
      @div class: 'coxide-align-center', =>
        @button outlet: 'btnReset', class: 'btn btn-size15 icon icon-sync', 'Reset'
        @button outlet: 'btnSave', class: 'btn btn-size15 icon icon-check', 'Save'
      
  initialize: () ->
    @modalPanel = atom.workspace.addModalPanel(item: @element, visible: true)
    @privateKey = atom.config.get('coxide.privateKey')
    if typeof @privateKey isnt 'undefined' and @privateKey isnt ''
      @edtPrvKey.setText(@privateKey)
    @btnCancel.on 'click', =>  @modalPanel.hide()
    @btnReset.on 'click', => @resetPrivateKey()
    @btnSave.on 'click', => @savePrivateKey()
  
  destroy: ->
    @element.remove()
    
  savePrivateKey: ->
    prvKey = @edtPrvKey.getText()
    if prvKey is ""  
      alert 'Empty Private Key!'
    else if prvKey.length != 16  
      alert 'Wrong Private Key! (Must be 16 characters)'
    else  
      serverURL = atom.config.get('coxide.serverURL')
      request serverURL + '/lib-latest-version/' + prvKey, (error, response, body) ->
        if error is null
          if body is "-1"
            alert "Server Error. Please retry later."
          else if body is "-2"
            alert "Invalid Private Key. Please check again."
          else
            atom.config.set('coxide.privateKey', prvKey)
            alert 'Private Key has been set successfully!'

  resetPrivateKey: ->
    atom.config.set('coxide.privateKey', "")
    alert 'Private Key has been reset!'
    @edtPrvKey.setText("")

