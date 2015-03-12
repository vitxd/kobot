# Description:
#   MongoDB log
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot something - some command
#
# Author:
#   Hais Deakin <h.deakin@quidco.com>

mongouri = process.env.HUBOT_MONGO_URI
return if !mongouri

Util = require 'util'

mongoose = require 'mongoose'
conn = mongoose.connect mongouri
Schema = mongoose.Schema

EVENT_MESSAGE = "msg"
EVENT_ENTER = "enter"
EVENT_LEAVE = "leave"
EVENT_TOPIC = "topic"

event = new Schema(
  {
    id: {type: String, min: 9, index: true},
    user_id: {type: String, min: 9, max: 10, index: true},
    text: String,
    room: {type: String},
    date: {type: Date, default: Date.now, index: true},
    event: {type: String, enum: [EVENT_MESSAGE, EVENT_ENTER, EVENT_LEAVE, EVENT_TOPIC]}
  }
)

Model = conn.model 'SlackEvent', event

logEvent = (msg, event) ->
  m = new Model
  m.id = msg.message.id
  m.text = msg.message.text
  m.user_id = msg.message.user.id
  m.room = msg.message.room
  m.event = event
  m.save()

module.exports = (robot) ->

  robot.hear /./i, (msg) ->
    logEvent msg, EVENT_MESSAGE

  robot.enter (msg) ->
    logEvent msg, EVENT_ENTER

  robot.leave (msg) ->
    logEvent msg, EVENT_LEAVE

  robot.topic (msg) ->
    logEvent msg, EVENT_TOPIC

  robot.respond /debug mongolog/i, (msg) ->
    Model.find({'room': msg.message.room}).limit(5).sort('-_id').exec((err, doc) ->
      msg.send "```" + Util.inspect(doc) + "```"
    )