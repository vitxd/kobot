# Description:
#   Detects and notifies of links that have already been posted.
#
# Dependencies:
#   None.
#
# Configuration:
#   None.
#
# Commands:
#  hubot posted when? - Returns a timestamp of when a repost occurred
#
# Authors:
#   Hais


pad = (n) ->
  return if n < 10 then '0' + n.toString(10) else n.toString(10)

buildTimestamp = (date) ->
  hs = date.getHours()
  mi = pad date.getMinutes()
  sc = pad date.getSeconds()
  dy = pad date.getDate()
  mo = pad date.getMonth() + 1
  yr = date.getFullYear()
  "#{hs}:#{mi}:#{sc} #{dy}/#{mo}/#{yr}"

module.exports = (robot) ->

  lastUrl = {}

  robot.respond /posted when\?/i, (msg) ->
    data = robot.brain.get "repostdata" || {}
    return if !lastUrl and !lastUrl[msg.message.room]
    return if !data[lastUrl[msg.message.room]]?
    report = data[lastUrl[msg.message.room]]
    date = new Date(report.date)
    timestamp = buildTimestamp date
    msg.send "First posted #{timestamp} by #{report.username}"

  robot.hear /(https?:\/\/\S*)/i, (msg) ->
    url = msg.match[0].toLowerCase()
    data = (robot.brain.get "repostdata") || {}
    if data[url]?
      msg.send "REPOST! http://i.imgur.com/CDfaE.gif"
      lastUrl[msg.message.room] = url
    else
      data[url] = {"date": (new Date).valueOf(), "username": msg.message.user.name}
      robot.brain.set "repostdata", data
      lastUrl[msg.message.room] = null
