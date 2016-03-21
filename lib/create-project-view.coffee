{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'
ipc = require 'ipc'
fs = require 'fs-plus'

utils = require './utils'

module.exports =
class CreateProjectView extends View 
  coxide = null
  modalPanel = null
  sep = null
  
  @content: ->
    @div class: 'coxide', =>
      @h1 class: 'icon icon-plus', =>
        @text "Create New Project"
        @span class: 'pull-right icon icon-x', outlet: 'btnCancel'
      
      @h2 "Project Name :"
      @subview 'edtProjName', new TextEditorView(mini: true, placeholderText: 'Please type new project name')
        
      @h2 "Workspace Path :"
      @subview 'edtWorkspacePath', new TextEditorView(mini: true, placeholderText: 'New Project will be created in workspace')
      @button outlet: 'btnWorkspacePath', class: 'btn btn-open-folder icon icon-file-directory pull-right'
      
      @h2 ""
      @div class: 'coxide-align-center', =>
        @button outlet: 'btnDoCreateProj', class: 'btn btn-size15 icon icon-flame', 'Done'
      
  initialize: (p) ->
    @coxide = p
    @modalPanel = atom.workspace.addModalPanel(item: @element, visible: false)
    @btnWorkspacePath.on 'click', => @selectWorkspacePath()
    @btnDoCreateProj.on 'click', => @doCreateProj()
    @btnCancel.on 'click', =>  @modalPanel.hide()
    @sep = utils.getSeperator()
    @installPath = utils.getInstallPath()
    
  doShow: ->
    if @modalPanel.isVisible() is false
      @modalPanel.show()
  
  destroy: ->
    @element.remove()
  
  selectWorkspacePath: ->
    responseChannel = "atom-create-project-response"
    ipc.on responseChannel, (path) =>
      ipc.removeAllListeners(responseChannel)
      if path isnt null
        if fs.existsSync(path[0] + @sep + ".atom-build.json") == false
          @edtWorkspacePath.setText(path[0])
        else
          alert('The selected path is including a project. Please select another path for workspace.');
    ipc.send('create-project', responseChannel)

  doCreateProj:  ->
    workspacePath = @edtWorkspacePath.getText()
    projectName = @edtProjName.getText()
    
    if projectName == ""
      alert 'Invalid Project Name.'
      return

    if fs.existsSync(workspacePath) == true
      if fs.existsSync(workspacePath + @sep + projectName) == true
        alert 'Same project already exists'
        return

      # check for currently opened project.
      if @coxide.closeProject() is false
        return
        
      projectPath = workspacePath + @sep + projectName
      fs.makeTreeSync(projectPath)
      fs.copySync(@installPath + @sep + "sample-proj" + @sep + "config", projectPath)
      if fs.existsSync(projectPath + @sep + "main.cpp") == false
        fs.copySync(@installPath + @sep + "sample-proj" + @sep + "template", projectPath)

      @coxide.projectPath = projectPath
      @modalPanel.hide()
      atom.project.setPaths([projectPath])
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
    else
      alert 'Invalid Workspace Path.'
