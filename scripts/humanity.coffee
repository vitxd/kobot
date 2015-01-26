# Description:
#   Play Cards Against Humanity in Hubot
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot q card - Returns a question
#   hubot card me - Displays an answer
#   hubot card 2 - Displays two answers for questions with two blanks
#
# Author:
#   Jonny Campbell (@jonnycampbell)

questions = require '../data/humanity/questions.json'
answers = require '../data/humanity/answers.json'

module.exports = (robot) ->
  robot.respond /card(?: me)?(?: )(\d+)?/i, (msg) ->
    count = if msg.match[1]? then parseInt(msg.match[1], 10) else 1
    msg.send msg.random answers for i in [1..count]

  robot.respond /q(?:uestion)? card/i, (msg) ->
    msg.send msg.random questions
