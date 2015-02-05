# Description:
#   Reddit me
#
# Commands:
#   hubot /r/<subreddit> - Picks a random post from subreddit
#   hubot ask question - Asks question from /r/AskReddit
#
#
# Author:
#   h.deakin@quidco.com

whiteList = /reddit|gold|comment|thread|karma|serious/i

module.exports = (robot) ->
  robot.respond /[\/]?r\/(.+)/i, (msg) ->
    subreddit = msg.match[1]
    msg.http("http://www.reddit.com/r/" + subreddit + "/hot.json")
    .get() (err, res, body) ->
      response = JSON.parse(body)
      children = response.data.children
      child = pickChild(children)
      return msg.send child.data.title + "\n" + child.data.url

  robot.respond /ask(?: the)?(?: channel)?(?: a)? question/i, (msg) ->
    msg.http("http://www.reddit.com/r/askreddit/hot.json")
    .get() (err, res, body) ->
      response = JSON.parse(body)
      children = response.data.children
      return if children.length < 10
      child = pickChild(children)
      child = pickChild(children) while child.data.title.match whiteList
      return msg.send child.data.title

  pickChild = (children) ->
    children[Math.floor(Math.random() * children.length)]