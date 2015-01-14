# Description:
#   Business cat
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot cat me - summons business cat
#
# Author:
#   Morgan Wigmanich <okize123@gmail.com> (https://github.com/okize)

images = require './../data/cats.json'

module.exports = (robot) ->
  robot.respond /cat me/i, (msg) ->
    msg.send msg.random images
