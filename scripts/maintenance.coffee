# Description:
#   Maintenance scripts
#
# Commands:
#   hubot self-update - Fetch, install & reload
#
#
# Author:
#   h.deakin@quidco.com

spawn = require('child_process').spawn

gitPath = process.env.HUBOT_GIT_PATH
npmPath = process.env.HUBOT_NPM_PATH

module.exports = (robot) ->

  robot.respond /self-update/i, (msg) ->
    msg.send "Running Git pull.."
    gitUpdate = spawn gitPath, ['pull']
    gitUpdate.stdout.on('data', (data) ->
      msg.send '```' + data + '```'
    )
    gitUpdate.stderr.on('data', (data) ->
      msg.send '```' + data + '```'
    )
    gitUpdate.on('close', (code) ->
      if (code == 0)
        msg.send "Git pull success, now running NPM install..."
        npmInstall = spawn npmPath, ['install']
        npmInstall.stdout.on('data', (data) ->
          msg.send '```' + data + '```'
        )
        npmInstall.stderr.on('data', (data) ->
          msg.send '```' + data + '```'
        )
        npmInstall.on('close', (code) ->
          if (code == 0)
            robot.brain.data.reloadRoom = msg.message.room
            msg.send "NPM Install success"
            msg.send "Shutting down"
            msg.robot.shutdown()
          else
            msg.send "NPM exit code " + code
        )
      else
        msg.send "Git exit code " + code
    );

  robot.on 'loaded', =>
    if (robot.brain.data.reloadRoom)
        robot.messageRoom robot.brain.data.reloadRoom, "Back online"
    robot.brain.data.reloadRoom = null