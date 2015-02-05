# Description:
#   Reddit me
#
# Commands:
#   hubot /r/<subreddit> - Picks a random post from subreddit
#   hubot ask question
#   hubot ask rude question
#   hubot what are you thinking
#   hubot idea - Inspire me
#   hubot fact - Teach me
#   hubot be funny - Supply a humorous image
#   hubot fuck up
#   hubot sanity check
#   hubot tell me a joke
#   hubot what should i know
#
#
# Author:
#   h.deakin@quidco.com

redditFilter = /reddit|gold|comment|thread|karma|serious|username|\/r\//i

module.exports = (robot) ->

  pickChild = (children) ->
    children[Math.floor(Math.random() * children.length)]

  query = (subreddit, filter, callback) ->
    filter ?= redditFilter
    robot.http("http://www.reddit.com/r/" + subreddit + "/hot.json")
    .get() (err, res, body) ->
      return if err
      response = JSON.parse(body)
      children = response.data.children
      return if children.length < 10
      child = pickChild(children)
      child = pickChild(children) while child.data.title.match filter
      callback child

  robot.respond /[\/]?r\/(.+)/i, (msg) ->
    query msg.match[1], null, (item) ->
      msg.send child.data.title + "\n" + child.data.url

  robot.respond /ask(?: the)?(?: channel)?(?: a)? question/i, (msg) ->
    query "askreddit", null, (item) ->
      msg.send item.data.title

  robot.respond /ask(?: the)?(?: channel)?(?: a)? (nsfw|rude) question/i, (msg) ->
    query "askredditnsfw", null, (item) ->
      msg.send item.data.title

  robot.respond /what are you thinking/i, (msg) ->
    query "showerthoughts", null, (item) ->
      msg.send item.data.title

  robot.respond /idea/i, (msg) ->
    query "shittyideas", null, (item) ->
      msg.send "Here's a great idea: " + item.data.title

  robot.respond /(?:tell )?(?:me )?something i (did not|didn\\'t) know/i, (msg) ->
    query "todayilearned", null, (item) ->
      msg.send item.data.title.replace(/til (?:that )?/i, "") + "\n" + item.data.url

  robot.respond /(?:be )?funny/i, (msg) ->
    query "funny", null, (item) ->
      msg.send item.data.title + "\n" + item.data.url

  robot.respond /fuck up/i, (msg) ->
    query "tifu", null, (item) ->
      msg.send item.data.title.replace(/tifu/i, "I fucked up")

  robot.respond /sanity check/i, (msg) ->
    query "DoesAnybodyElse", null, (item) ->
      msg.send item.data.title.replace(/dae/i, "Does anyone else")

  robot.respond /make me hungry/i, (msg) ->
    query "foodporn", null, (item) ->
      msg.send item.data.url

  robot.respond /(?:tell )?(?:me )?(?:a )?joke/i, (msg) ->
    query "jokes", null, (item) ->
      msg.send "*" + item.data.title + "*\n>" + item.data.selftext

  robot.respond /what should i buy/i, (msg) ->
    query "shutupandtakemymoney", null, (item) ->
      msg.send item.data.title + "\n" + item.data.url




