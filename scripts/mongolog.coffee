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
#   hubot something - somec ommand
#
# Author:
#   Hais Deakin <h.deakin@quidco.com>

mongouri = process.env.HUBOT_MONGO_URI
return if !mongouri

mongoose = require 'mongoose'
conn = mongoose.connect mongouri
Schema = mongoose.Schema

event = new Schema(
  {
    id: { type: String, min: 9, index: true },
    user_id: { type: String, min: 9, max: 10, index: true },
    text: String,
    room: { type: String },
    date: { type: Date, default: Date.now, index: true }
  }
)

Model = conn.model 'SlackEvent', event

module.exports = (robot) ->

  robot.hear /./i, (msg) ->
    m = new Model
    m.id = msg.message.id
    m.text = msg.message.text
    m.user_id = msg.message.user.id
    m.room = msg.message.room
    m.save()
