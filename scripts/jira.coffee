# Description:
#   Maintenance scripts
#
# Commands:
#   <JIRA Ticket> - Responds with expanded info
#
#
# Author:
#   h.deakin@quidco.com

async = require 'async'
quidbot = require 'quidbot'


regex = new RegExp  process.env.HUBOT_JIRA_TICKET_PATTERN, 'gi'
JIRA_URL = process.env.HUBOT_JIRA_URL
JIRA_AUTH = process.env.HUBOT_JIRA_AUTH


SLACK_LOGO = "https://slack.global.ssl.fastly.net/14542/img/services/jira_48.png"

slack = new quidbot.SlackClient("Jira", SLACK_LOGO)

module.exports = (robot) ->

  robot.hear regex, (msg) ->

    for ticketId in msg.message.text.match regex
      async.seq(getTicket, build) {ticketId: ticketId, room: msg.room}, (err, result) ->
        console.log err if err

  getColour = (colour) ->
    switch colour
      when "green" then return "#14892c"
      when "yellow" then return "#ffd351"
      when "blue-gray" then return "#4a6785"
      else return  "#ccc"

  getTicket = (data, callback) ->
    robot.http("#{JIRA_URL}rest/api/2/issue/#{data.ticketId}")
    .header("Authorization", JIRA_AUTH)
    .get() (err, res, body) ->
      return callback err if err
      data.ticketData = JSON.parse body
      callback null, data

  build = (data, callback) ->
    ticket = data.ticketData
    ticketKey = ticket.key
    projectKey = ticket.fields.project.key
    projectName = ticket.fields.project.name
    ticketType = ticket.fields.issuetype.name
    msg = "<#{JIRA_URL}browse/#{projectKey}|#{projectName}> #{ticketType} <#{JIRA_URL}browse/#{ticketKey}|#{ticketKey}>"
    fields = []
    fields.push slack.buildGroup("Summary", ticket.fields.summary, false)
    fields.push slack.buildGroup("Reporter", ticket.fields.reporter.displayName, true) if ticket.fields.reporter.displayName?
    fields.push slack.buildGroup("Assigned", ticket.fields.assignee.displayName, true) if ticket.fields.assignee?
    fields.push slack.buildGroup("Status", ticket.fields.status.name, true)
#    description = ticket.fields.description
    colour = ticket.fields.status.statusCategory.colorName
    console.log colour
    attachments = [slack.buildAttachment(msg, getColour(colour), fields)]
    slack.post("##{data.room}", "", attachments, callback)

