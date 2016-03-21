CreateProjectView = require './create-project-view'
SetPrivateKeyView = require './set-private-key-view'
UpdateView = require './update-view'
TopToolbarView = require './top-toolbar-view'
utils = require './utils'

{CompositeDisposable} = require 'atom'
ipc = require 'ipc'
fs = require 'fs-plus'
{spawn} = require 'child_process'
{View} = require 'space-pen'
{SelectListView} = require 'atom-space-pen-views'
request = require 'request'
rmdir = require 'rimraf'

module.exports = Coxide =
  subscriptions: null
  createProjectView: null
  topToolbarView: null
 
  projectPath: null
  installPath: null
  sep: null

  activate: (state) ->
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
    
    @installPath = utils.getInstallPath()
    @sep = utils.getSeperator()
    
    serverURL = atom.config.get('coxide.serverURL')
    privateKey = atom.config.get('coxide.privateKey')
    if typeof privateKey is 'undefined' || privateKey is ''
      privateKey = ''

    if atom.project.getPaths()[0] isnt undefined
      @projectPath = atom.project.getPaths()[0]
    
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 
                'coxide:createProject': => @createProject(), 
                'coxide:openProject': => @openProject(),
                'coxide:closeProject': => @closeProject(),
                'coxide:viewVersion': => @viewVersion(),
                'coxide:viewLicense': => @viewLicense(),
                'coxide:libUpdate': => @libUpdate(),
                'coxide:setPrivateKey': => @setPrivateKey()
    
    @createProjectView = new CreateProjectView(@)
    @topToolbarView = new TopToolbarView()
  
    @libUpdate()
    @checkNotUsedToolchain()

  setPrivateKey: ->
    new SetPrivateKeyView()

  createProject: ->
    @createProjectView.doShow()
  
  openProject: ->
    responseChannel = "atom-open-project-response"
    ipc.on responseChannel, (path) =>
      ipc.removeAllListeners(responseChannel)
      if path isnt null 
        if path[0] == @projectPath
          alert 'This project is already opened.' 
        else if fs.existsSync(path[0] + @sep + ".atom-build.json") == true
          if @closeProject() is false
            return
          @projectPath = path[0]
          atom.project.setPaths(path)
          atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:show')
          @topToolbarView.loadTargetDevice()
        else
          alert 'No exist available project in this path.'
    ipc.send('open-project', responseChannel)    
  
  closeProject: ->
    if @projectPath isnt null    
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

  _isProjectModified: ->
    textEditors = atom.workspace.getTextEditors()
    for editor in textEditors
      if editor.isModified() is true and editor.getPath() isnt null
        path = "" + editor.getPath()
        return true if path.indexOf(@projectPath) == 0
    return false

  _clearProject: ->
    atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:detach')
    atom.project.removePath(@projectPath)
    @projectPath = null
    @topToolbarView.clearTargetDevice()
  
  _closeFiles: (flag) ->
    panes = atom.workspace.getPanes() 
    for pane in panes 
      for item in pane.getItems()
        path = "" + item.getPath()
        if path isnt null and path.indexOf(@projectPath) == 0
            if flag == 'save'
              item.save() if item.isModified() is true  
            item.destroy()

  viewVersion: ->
    for versionInfo in atom.packages.getAvailablePackageMetadata()
      if versionInfo.name == "coxide"
        alert "Nol.A IDE version " + versionInfo.version + "\nCopyright 2016 CoXlab Inc. All rights reserved."

  viewLicense: ->
    atom.workspace.open(utils.getLicensePath())

  libUpdate: ->
    serverURL = atom.config.get('coxide.serverURL')
    privateKey = atom.config.get('coxide.privateKey')
    if typeof privateKey is 'undefined' || privateKey is ''
      privateKey = ''
    request serverURL + '/lib-latest-version/' + privateKey, (error, response, body) =>
      if error is null
        if body is "-1"
          atom.notifications.addInfo "Server Error. Please retry later."
        else if body is "-2"
          atom.notifications.addInfo "Private key is NOT valid.",
            detail : "Please reset or update on [Help] -> [Setting Private Key]"
        else
          @updateCheck(JSON.parse(body), true)
          
  updateCheck: (libInfo, feedback) ->
    updateList = @_makeUpdateList(libInfo)
    if updateList.length > 0
      updateInfoStr = ""
      for i in [0...updateList.length]
        if updateList[i].libOldVer is "NEW"
          updateInfoStr = updateInfoStr + (i+1) + ". " + updateList[i].libName + \
            " [ New " + updateList[i].libNewVer + " ]\n"
        else if updateList[i].libNewVer is "DELETE"
          updateInfoStr = updateInfoStr + (i+1) + ". " + updateList[i].libName + \
            " [ Delete " + updateList[i].libOldVer + " ]\n"
        else
          updateInfoStr = updateInfoStr + (i+1) + ". " + updateList[i].libName + \
            " [ " + updateList[i].libOldVer + " -> " + updateList[i].libNewVer + "]\n"
      noti = atom.notifications.addInfo "New Update For Libraries!",
          dismissable: true,
          buttons: [{
            text: 'Update'
            className: 'btn-updateDo'
            onDidClick: => 
              noti.dismiss()
              @doUpdate(updateList)
          }],
          detail : updateInfoStr
    else 
      if feedback == true
        atom.notifications.addInfo "You already have the latest version!"

  _makeUpdateList: (libInfo) ->
    libVers = atom.config.get('coxide.libVersions')
    updateList = []
    for x in [0...libVers.length]
      for y in [0...libInfo.length]
        if libVers[x].libType == libInfo[y].libType
          if libVers[x].libVersion != libInfo[y].libVersion
            # Found new version of existing library.
            updateList.push({ libName: libInfo[y].libName, libType: libInfo[y].libType, \
                              libOldVer: libVers[x].libVersion, libNewVer: libInfo[y].libVersion, \
                              libToolchain : libInfo[y].libToolchain })
          break
        if y == libInfo.length-1
          # Found Deleted Library.
          updateList.push({ libName: libVers[x].libName,libType: libVers[x].libType, \
                            libOldVer: libVers[x].libVersion, libNewVer: "DELETE" })
    
    for x in [0...libInfo.length]
      # Found new libraries
      if libVers.length == 0
        updateList.push({ libName: libInfo[x].libName, libType: libInfo[x].libType, \
                          libOldVer: "NEW", libNewVer: libInfo[x].libVersion, \
                          libToolchain : libInfo[x].libToolchain })
      else      
        for y in [0...libVers.length]
          if libInfo[x].libType == libVers[y].libType
            break
          if y == libVers.length-1
            updateList.push({ libName: libInfo[x].libName, libType: libInfo[x].libType, \
                              libOldVer: "NEW", libNewVer: libInfo[x].libVersion, \
                              libToolchain : libInfo[x].libToolchain })
    return updateList
        
  doUpdate: (updateList) ->
    updateView = new UpdateView(updateList)
    updatePanel = atom.workspace.addModalPanel(item: updateView.element, visible: true)
    updateView.setPanel(updatePanel)
    updateView.doUpdate()
    
  checkNotUsedToolchain: ->
    # Check not-used-toolchain and remove them. 
    installedTools = atom.config.get('coxide.toolchains')
    libVersions = atom.config.get('coxide.libVersions')
    deleteList = []
    for i in [0...installedTools.length]
      found = 0
      for j in [0...libVersions.length]
        if libVersions[j].libToolchain == installedTools[i]
          found = 1
      if found == 0
        deleteList.push(installedTools[i])
    if deleteList.length > 0
      noti = atom.notifications.addInfo "Unused toolchains have been deleted in background.",
        dismissable: true
      toolPath = @installPath + @sep + "cox-sdk" + @sep + "tools" + @sep
      for i in [0...deleteList.length]
        rmdir.sync toolPath + deleteList[i]
        idx = installedTools.indexOf(deleteList[i]);
        installedTools.splice(idx, 1);
      atom.config.set('coxide.toolchains', installedTools)
