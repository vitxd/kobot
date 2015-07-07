# Description:
#   imgur
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   [imgur url] - Show extended data on image
#
# Author:
#   Hais Deakin <h.deakin@quidco.com>

module.exports = (robot) ->

  return robot.logger.error "Missing configuration HUBOT_IMGUR_CLIENT_ID" unless process.env.HUBOT_IMGUR_CLIENT_ID?

  robot.hear /i\.imgur\.com\/([A-z0-9]+)\.([A-z0-9]+)/i, (msg) ->
    robot.http("https://api.imgur.com/3/image/" + msg.match[1])
    .header('Authorization', 'Client-ID ' + clientid)
    .get() (err, res, body) ->
      return if err
      response = JSON.parse(body)
      return if !response.success
      title = response.data.title
      return if !title
      str = "*" + title + "*"
      str += "\n>" + response.data.description.replace(/(?:\r\n|\r|\n)/g, "\n>") + "\n\n" if response.data.description
      str += "\n" + response.data.link.replace(msg.match[1] + "h", msg.match[1]) if msg.match[2] in ['gifv', 'webm'] and response.data.link
      msg.send str

