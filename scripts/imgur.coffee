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

clientid = process.env.HUBOT_IMGUR_CLIENT_ID
return if !clientid

module.exports = (robot) ->
  robot.hear /i\.imgur\.com\/([A-z0-9]+)\.([A-z0-9]+)/i, (msg) ->
    console.log msg.match[1]
    console.log msg.match[2]
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
      str += "\n" + response.data.link if msg.match[2] == 'gifv'
      msg.send str

