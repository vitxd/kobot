# Description:
#   Maintenance scripts
#
# Commands:
#   hubot update and restart - Fetch, install & reload
#   hubot update git - Perform git pull
#   hubot update npm - Perform npm install
#   hubot show version - Show git revision
#
#
# Author:
#   h.deakin@quidco.com

spawn = require('child_process').spawn

gitPath = process.env.HUBOT_GIT_PATH
npmPath = process.env.HUBOT_NPM_PATH

delay = (ms, func) -> setTimeout func, ms

sleep = (ms) ->
  start = new Date().getTime()
  continue while new Date().getTime() - start < ms

isRestarting = false

runCmd = (robot, room, cmd, args, next) ->
  child = spawn cmd, args
  robot.messageRoom(room, "Running `" + cmd + " " + args.join(" ") + "`")
  output = ""
  child.stdout.on('data', (data) ->
    output += data
  )
  child.stderr.on('data', (data) ->
    output += data
  )
  child.on('close', (code) ->
    if (output.length)
      robot.messageRoom(room, "```" + output + "```")
    if (code != 0)
      robot.messageRoom(room, "Fail (" + code + ")")
    else
      if next
        next(robot, room, next)
      else
        robot.messageRoom(room, "Success")
  )

updateGit = (robot, room, next) ->
  return runCmd(robot, room, gitPath, ["pull"], next)

updateNpm = (robot, room, next) ->
  return runCmd(robot, room, npmPath, ["install"], next)

getRevision = (robot, room, next) ->
  return runCmd(robot, room, gitPath, ["log", "--oneline", "-n", "1"])

respawnBot = (robot, room) ->
  robot.messageRoom room, "Restarting..."
  isRestarting = true
  robot.brain.set "maintenanceReloadRoom", room
  robot.brain.save()
  robot.shutdown()
#  delay 3000, -> console.log "Robot is " + robot

module.exports = (robot) ->
  robot.respond /update git/i, (msg) ->
    room = msg.message.user.room
    updateGit robot, room

  robot.respond /update npm/i, (msg) ->
    room = msg.message.user.room
    updateNpm robot, room

  robot.respond /update and restart/i, (msg) ->
    room = msg.message.user.room
    updateGit(robot, room, (robot, room, next) ->
      updateNpm(robot, room, (robot, room, next) ->
        respawnBot(robot, room)
      )
    )

  robot.respond /show version/i, (msg) ->
    room = msg.message.user.room
    getRevision(robot, room)

  robot.respond /respawn/i, (msg) ->
    room = msg.message.user.room
    respawnBot(robot, room)

  robot.brain.on 'loaded', =>
    room = robot.brain.get "maintenanceReloadRoom"
    if (!isRestarting && room != null && room.length)
      robot.messageRoom room, "Back online!"
      robot.brain.set "maintenanceReloadRoom", ""