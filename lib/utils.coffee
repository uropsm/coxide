utils = require './utils.coffee'
remote = require 'remote'
app = remote.require('app')
os = require 'os'

exports.getInstallPath = ->
  sep = ""
  uselessPath = ""
  appPath = app.getAppPath()

  platform = os.platform()
  if platform == "linux" || platform == "darwin"
    sep = "/"
    uselessPath = sep + "share" + sep + "atom" + sep + "resources" + sep + "app.asar"
  else if platform == "win32" || platform == "win64"
    sep = "\\"
    uselessPath = sep + "Atom" + sep + "resources" + sep + "app.asar"
  
  installPath = appPath.replace(uselessPath, "")
  return installPath

exports.getSeperator = ->
  platform = os.platform()
  if platform is "linux" or platform is "darwin"
    return "/"
  else if platform is "win32" or platform is "win64"
    return "\\"

exports.getLicensePath = ->
  installPath = utils.getInstallPath()
  sep = utils.getSeperator()
  licensePath = ""

  platform = os.platform()
  if platform == "linux" || platform == "darwin"
    licensePath = sep + "share" + sep + "atom" + sep + "resources" + sep + "LICENSE.md"
  else if platform == "win32" || platform == "win64"
    licensePath = sep + "Atom" + sep + "resources" + sep + "LICENSE.md"
  
  return installPath + licensePath

exports.getSerialMonitorPath = ->
  installPath = utils.getInstallPath()
  sep = utils.getSeperator()
  serialMonitorPath = ""

  platform = os.platform()
  if platform == "linux" || platform == "darwin"
    serialMonitorPath = sep + "serial_monitor" + sep + "nw"
  else if platform == "win32" || platform == "win64"
    serialMonitorPath = sep + "serial_monitor" + sep + "nw.exe"
  
  return installPath + serialMonitorPath






