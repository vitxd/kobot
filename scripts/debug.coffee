# Description:
#   Urban dictionary
#
# Commands:
#   hubot debug message - output message information
#   hubot debug brain - output robot storage
#
#
# Author:
#   h.deakin@quidco.com


Util = require "util"

module.exports = (robot) ->

  robot.respond /debug message/i, (msg) ->
    return msg.send Util.inspect(msg.message)

  robot.respond /debug brain/i, (msg) ->
    return msg.send Util.inspect(robot.brain.data)
