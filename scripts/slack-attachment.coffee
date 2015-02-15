# Description:
#   Enable again the 'slack-attachment' event
#
# Environment:
#   HUBOT_SLACK_INCOMING_WEBHOOK

slack = require 'hubot-slack'

module.exports = (robot) ->
  options =
    webhook: process.env.HUBOT_SLACK_INCOMING_WEBHOOK

  return robot.logger.error "Missing configuration HUBOT_SLACK_INCOMING_WEBHOOK" unless options.webhook?

  getChannel = (msg) ->
    if msg.room.match /[C|G|U]02/
      # the room already matches an ID
      msg.room
    else if msg.room.match /^[#@]/
      # the channel already has an appropriate prefix
      msg.room
    else if msg.user && msg.room == msg.user.name
      "@#{msg.room}"
    else
      "##{msg.room}"

  getUsername = (data) ->
    data.username || robot.name

  attachment = (data) ->
    payload = data.content

    payload.channel  = data.channel || getChannel data.message
    payload.username = getUsername data

    if data.icon_url?
      payload.icon_url = data.icon_url
    else if data.icon_emoji?
      payload.icon_emoji = data.icon_emoji
    else if payload.username == robot.name
      # use the image from our bot's user object, if present
      if robot.adapter instanceof slack.SlackBot
        profile = robot.adapter.client.getUserByID(robot.adapter.client.self.id)?.profile
        if profile?
          # I'd like to think that image_192 will always exist, but I don't want to rely on it
          for key in ['image_192', 'image_72', 'image_48', 'image_32', 'image_24']
            image_url = profile[key]
            if image_url?
              payload.icon_url = image_url
              break

    reqbody = JSON.stringify(payload)

    robot.http(options.webhook)
    .header("Content-Type", "application/json")
    .post(reqbody) (err, res, body) ->
      return if res.statusCode == 200

      robot.logger.error "Error!", res.statusCode, body

  robot.on "slack-attachment", (data) ->
    robot.logger.warning "Using deprecated event 'slack-attachment'"
    attachment data

  robot.on "slack.attachment", (data) ->
    attachment data
