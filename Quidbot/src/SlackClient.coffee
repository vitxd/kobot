qs = require "querystring"

class SlackClient

  SLACK_API: "https://slack.com/api/chat.postMessage"

  # Slack API token
  apiToken: ""

  # Define username and icon
  username: ""
  icon: ""

  constructor: (@username, @icon) ->
    @apiToken = process.env.HUBOT_SLACK_API_TOKEN

  post: (channelId, text, attachments, callback) ->
    fields = {
      'text': text,
      'token': @apiToken,
      'channel': channelId,
      'username': @username,
      'icon_url': @icon
    }
    fields['attachments'] = JSON.stringify(attachments) if attachments
#    log Util.inspect fields
    robot.http(@SLACK_API)
    .header('Content-type', 'application/x-www-form-urlencoded')
    .post(qs.stringify(fields)) callback

  buildAttachment: (title, colour, fields) ->
    return {'text': "#{title}", 'color': colour, 'fields': fields}

  buildGroup: (title, value, short) ->
    return {'title': "#{title}", 'value': "#{value}", 'short': short}

module.exports = SlackClient