# Description:
#   Reddit me
#
# Commands:
#   hubot /r/<subreddit> me - Defines a word/phrase
#
#
# Author:
#   h.deakin@quidco.com

module.exports = (robot) ->

  robot.respond /\/r\/(.+) me/i, (msg) ->
    subreddit = msg.match[1]
    msg.http("http://www.reddit.com/r/"+subreddit+"/hot.json")
    .get() (err, res, body) ->
      response = JSON.parse(body)
      children = response.data.children
      child = children[Math.floor(Math.random() * children.length)]
      return msg.send child.data.title + "\n" + child.data.url