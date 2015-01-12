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

sleep = (ms) ->
  start = new Date().getTime()
  continue while new Date().getTime() - start < ms

module.exports = (robot) ->
  robot.respond /self-update/i, (msg) ->
    msg.send "Running `" + gitPath + " pull`"
    gitUpdate = spawn gitPath, ['pull']
    output = ""
    gitUpdate.stdout.on('data', (data) ->
      output += data + "\n"
    )
    gitUpdate.stderr.on('data', (data) ->
      output += data + "\n"
    )
    gitUpdate.on('close', (code) ->
      output = "```" + output + "```\n"
      sleep(2000)
      if (code == 0)
        msg.send output + "Success, now running `" + npmPath + " install`"
        output = ""
        npmInstall = spawn npmPath, ['install']
        npmInstall.stdout.on('data', (data) ->
          output += data + "\n"
        )
        npmInstall.stderr.on('data', (data) ->
          output += data + "\n"
        )
        npmInstall.on('close', (npmCode) ->
          sleep(2000)
          output = "```" + output + "```\n"
          if (npmCode == 0)
            robot.brain.data.reloadRoom = msg.message.room
            output += "Success, restarting..."
            msg.send output
            sleep(2000)
            msg.robot.shutdown()
          else
            msg.send output + "NPM exit code " + npmCode
        )
      else
        msg.send output + "Git exit code " + code
    );

  robot.on 'loaded', =>
    if (robot.brain.data.reloadRoom)
      robot.messageRoom robot.brain.data.reloadRoom, "Back online!"
    robot.brain.data.reloadRoom = null