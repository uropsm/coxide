CreateProjectView = require './create-project-view'
TopToolbarView = require './top-toolbar-view'
ToolbarButtonView = require './toolbar-button-view'
DeviceSelectView = require './device-select-view'
{CompositeDisposable} = require 'atom'
ipc = require 'ipc'
fs = require 'fs-plus'
{spawn} = require 'child_process'
{View} = require 'space-pen'
{SelectListView} = require 'atom-space-pen-views'

createProjectView = null
workspacePath = null
projectPath = null
projectName = null
  
module.exports = Coxide =
  subscriptions: null
  modalPanel: null
  topToolbarView: null
  
  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 
                'coxide:createProject': => @createProject(), 
                'coxide:openProject': => @openProject(),
                'coxide:closeProject': => @closeProject()
                
    createProjectView = new CreateProjectView
    @modalPanel = atom.workspace.addModalPanel(item: createProjectView.element, visible: false)
  
    btnWorkspacePath = createProjectView.getElementByName('btnWorkspacePath')  
    btnWorkspacePath.on 'click', =>  @selectWorkspacePath()
    btnDoCreateProj = createProjectView.getElementByName('btnDoCreateProj')  
    btnDoCreateProj.on 'click', =>  @doCreateProj()
    btnCancel = createProjectView.getElementByName('btnCancel')  
    btnCancel.on 'click', =>  @modalPanel.hide() 

    @topToolbarView = new TopToolbarView()
    atom.workspace.addTopPanel item: @topToolbarView
    
    guideOpt = {
      tooltip: "Guide",
      icon: "book",
      callback: @guideLink
    }
    guideBtn = new ToolbarButtonView(guideOpt)
    @topToolbarView.addItem(guideBtn)
    
    serialOpt = {
      tooltip: "Serial Port",
      icon: "checklist",
      callback: @serialPort
    }
    serialBtn = new ToolbarButtonView(serialOpt)
    @topToolbarView.addItem(serialBtn)
  
  deactivate: ->
    @toolBar?.removeItems()
  
  serialize: ->

  serialPort: ->
    spawn('C:\\NOL.A\\serial_monitor\\nw.exe', [ '.' ], { })

  createProject: ->  
    if @modalPanel.isVisible() is false
      @modalPanel.show()
  
  doCreateProj:  ->
    edtWorkspacePath = createProjectView.getElementByName('edtWorkspacePath') 
    workspacePath = edtWorkspacePath.getModel().getText()
    
    edtProjName = createProjectView.getElementByName('edtProjName') 
    projectName = edtProjName.getModel().getText()
    
    if projectName == ""
      alert 'Invalid Project Name.'
      return
          
    if fs.existsSync(workspacePath) == true
      if fs.existsSync(workspacePath + "\\" + projectName) == true
        alert 'Same project already exists'
        return
        
      if @closeProject() is false
        return
        
      projectPath = workspacePath + "\\" + projectName
      fs.makeTreeSync(projectPath)
      fs.copySync("C:\\NOL.A\\sample-proj\\config", projectPath)
      if fs.existsSync(projectPath + "\\main.c") == false
        fs.copySync("C:\\NOL.A\\sample-proj\\template", projectPath)
  
      atom.project.setPaths([projectPath])
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
      @modalPanel.hide()
    else
      alert 'Invalid Workspace Path.'
      
  selectWorkspacePath: ->
    responseChannel = "atom-create-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null
        if fs.existsSync(path[0] + "\\.atom-build.json") == false
          edtWorkspacePath = createProjectView.getElementByName('edtWorkspacePath') 
          edtWorkspacePath.getModel().setText(path[0])
        else
          alert('Project exists already in this path.');
    ipc.send('create-project', responseChannel)
  
  openProject: ->
    responseChannel = "atom-open-project-response"
    ipc.on responseChannel, (path) ->
      ipc.removeAllListeners(responseChannel)
      if path isnt null 
        if path[0] == projectPath
          alert 'This project is already opened.' 
        else if fs.existsSync(path[0] + "\\.atom-build.json") == true
          if Coxide.closeProject() is false
            return
          atom.project.setPaths(path)
          atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
          projectPath = path[0]
        else
          alert 'No exist available project in this path.'
    ipc.send('open-project', responseChannel)    
  
  _isProjectModified: ->
    textEditors = atom.workspace.getTextEditors()
    for editor in textEditors
      if editor.isModified() is true and editor.getPath() isnt null
        path = "" + editor.getPath()
        return true if path.indexOf(projectPath) == 0
    return false
 
  _clearProject: ->
    atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:detach')
    atom.project.removePath(projectPath)
    projectPath = null
  
  _closeFiles: (flag) ->
    panes = atom.workspace.getPanes() 
    for pane in panes 
      for item in pane.getItems()
        path = "" + item.getPath()
        if path isnt null and path.indexOf(projectPath) == 0
            if flag == 'save'
              item.save() if item.isModified() is true  
            item.destroy()

  closeProject: ->
    if projectPath isnt null    
      if @_isProjectModified() is true
        atom.confirm
          message: 'The current project has changes. Do you want to save them? Your changes will be lost if you close without saving'
          buttons:
            'Save': -> 
              Coxide._closeFiles('save')
              Coxide._clearProject() 
              return true
            'Don\'t save': -> 
              Coxide._closeFiles()
              Coxide._clearProject()
              return true
            'Cancel': ->
              return false
      else
        @_closeFiles()
        @_clearProject()
        return true

  guideLink : ->
    shell = require 'shell'
    shell.openExternal('http://www.coxlab.kr/index.php/docs/')