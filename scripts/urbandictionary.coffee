# Description:
#   Urban dictionary
#
# Commands:
#   hubot define <term> - Defines a word/phrase
#
#
# Author:
#   h.deakin@quidco.com

module.exports = (robot) ->

  robot.respond /define (.+)?/i, (msg) ->
    term = msg.match[1]
    msg.http("http://api.urbandictionary.com/v0/define?term=" + term)
    .get() (err, res, body) ->
      response = JSON.parse(body)
      for result, i in response.list
        str = "*" + result.word + "*\n"
        str += result.definition + "\n\n"
        str += "_" + result.example + "_\n\n"
        str += "Related: " + response.tags.join(", ")
        return msg.send str