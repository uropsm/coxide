{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class CreateProjectView extends View 
  @content: ->
    @div class: 'coxide', =>
      @h1 class: 'icon icon-plus', =>
        @text "Create New Project"
        @span class: 'pull-right icon icon-x', outlet: 'btnCancel'
      
      @h2 "Project Name :"
      @subview 'edtProjName', new TextEditorView(mini: true, placeholderText: 'Please type new project name')
        
      @h2 "Workspace Path :"
      @subview 'edtWorkspacePath', new TextEditorView(mini: true, placeholderText: 'Project folder will be created in this directory')
      @button outlet: 'btnWorkspacePath', class: 'btn btn-open-folder icon icon-file-directory pull-right'
      
      @h2 ""
      @div class: 'coxide-align-center', =>
        @button outlet: 'btnDoCreateProj', class: 'btn btn-size15 icon icon-flame', 'Do it'
      
  initialize: () ->
    
  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()
    
  getElementByName: (name) ->
    if(name is 'btnCancel')
      return @btnCancel
    else if(name is 'edtProjName')
      return @edtProjName
    else if(name is 'edtWorkspacePath')
      return @edtWorkspacePath
    else if(name is 'btnWorkspacePath')
      return @btnWorkspacePath
    else if(name is 'btnDoCreateProj')
      return @btnDoCreateProj
    else
      return null
