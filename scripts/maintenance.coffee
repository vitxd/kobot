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
    cmd = gitPath + " pull && " + npmPath + " install"
    msg.send "Running `"+cmd+"`"
    gitUpdate = spawn '/bin/bash', ['-c',  cmd]
    output = ""
    gitUpdate.stdout.on('data', (data) ->
      output += data + "\n"
    )
    gitUpdate.stderr.on('data', (data) ->
      output += data + "\n"
    )
    gitUpdate.on('close', (code) ->
      output = "```" + output + "```\n"
      if (code == 0)
        output += "Success, restarting..."
        msg.send output
        robot.brain.set('reloadRoom', msg.message.user.room)
        msg.robot.shutdown()
      else
        msg.send output + "Fail: Exit code " + code
    );

  robot.on 'loaded', =>
    if (robot.brain.get('reloadRoom'))
      robot.messageRoom robot.brain.get('reloadRoom'), "Back online!"
    robot.brain.set('reloadRoom', 0)