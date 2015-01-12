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
          if (output.length)
            output = "```" + output + "```\n"
          if (npmCode == 0)
            output += "Success, restarting..."
            msg.send output
            robot.brain.set('reloadRoom', msg.message.room)
            msg.robot.shutdown()
          else
            msg.send output + "NPM exit code " + npmCode
        )
      else
        msg.send output + "Git exit code " + code
    );

  robot.on 'loaded', =>
    if (robot.brain.get('reloadRoom'))
      robot.messageRoom robot.brain.get('reloadRoom'), "Back online!"
    robot.brain.set('reloadRoom', 0)