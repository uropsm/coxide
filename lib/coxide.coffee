CreateProjectView = require './create-project-view'
{CompositeDisposable} = require 'atom'
ipc = require 'ipc'
fs = require 'fs-plus'
{spawn} = require 'child_process'

createProjectView = null
workspacePath = null
projectPath = null
projectName = null
  
module.exports = Coxide =
  subscriptions: null
  modalPanel: null
  
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
    
  deactivate: ->
    @toolBar?.removeItems()
  
  serialize: ->
    
  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'coxide-tool-bar'

    @toolBar.addButton
      icon: 'checklist',
      callback: @serialPort
      tooltip: 'Serial Port'
      
    @toolBar.addButton
      icon: 'book',
      callback: @guideLink
      tooltip: 'Guide'

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
      projectPath = workspacePath + "\\" + projectName
      if fs.existsSync(projectPath) == true
        alert 'Same project already exists'
        return
      
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
        if fs.existsSync(path[0] + "\\.atom-build.json") == true
            atom.project.setPaths(path)
            atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
            projectPath = path[0]
        else
            alert('Failed : no available project in this path.');
    ipc.send('open-project', responseChannel)    
  
  closeProject : ->
    if projectPath isnt null
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:detach')
      atom.project.removePath(projectPath)
      projectPath = null
 
  guideLink : ->
    shell = require 'shell'
    shell.openExternal('http://www.coxlab.kr/index.php/docs/')