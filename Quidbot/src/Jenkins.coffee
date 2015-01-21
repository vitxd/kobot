async = require 'async'
Util = require "util"
qs = require "querystring"
success = require '../../src/main/json/success.json'

class Jenkins extends Quidbot

  SLACK_USER: "Jenkins"
  SLACK_ICON: "https://slack.global.ssl.fastly.net/20653/img/services/jenkins-ci_48.png"

  COLOUR_GREEN: "#94c22f"
  COLOUR_RED: "#d33833"
  COLOUR_YELLOW: "#d3b633"

  MAX_MESSAGE_LENGTH: 3000

  JOB_QUERY_STR: """
    actions[causes[shortDescription,userId,userName]]{0},
    changeSet[kind,items[commitId]],
    building, duration,
    fullDisplayName, id,
    number, result,
    timestamp, url
  """.replace /^\s+|\s+$/g,''

  TEST_REPORT: """
    duration, empty,
    failCount, passCount, skipCount,
    suites[cases[age,duration,errorDetails,name,className,status,failedSince]]
  """.replace /^\s+|\s+$/g,''

  # Hubot robot instance
  robot

  # Slack API Instance
  slack

  listeners

  constructor: (@robot) ->
    @slack = new Slack process.env.HUBOT_SLACK_API_TOKEN, @SLACK_USER, @SLACK_ICON
    @listeners = @getConfig()

  @handleEvent: (event) ->
    @flatten(event)

  @getConfig: (jenkinsConfig) ->
    jenkinsConfig ?= process.env.HUBOT_JENKINS_LISTENERS
    matches = {}
    matches = require jenkinsConfig if jenkinsConfig
    for channel, events of matches
      for event in events
        for eventName, regex of event
          opt = ''
          if typeof regex isnt 'string'
            opt = regex[1]
            regex = regex[0]
          regex =  new RegExp regex, opt
    return matches;

  @buildChangelog = (revisions, callback) ->
    @log "buildChangeLog " + Util.inspect revisions
    fields = []
    fields.push buildGroup 'Revisions', revisions.length, true
    fields.push buildGroup 'Authors', @countAuthors(revisions), true
    for editType, editCount in countEditTypes revisions
      fields.push buildGroup "Files #{editType}", editCount, true
    changeLogGroups = formatChangeLog revisions
    changeLogGroupsSize = changeLogGroups.length
    part = 1
    for logGroup in changeLogGroups
      title = "Changelog"
      if changeLogGroups.length > 1
        title += " (part #{part} of #{changeLogGroupsSize})"
        part++
      fields.push @buildGroup(title, logGroup, false)
    callback null, "Release test", [@buildAttachement "Groups", @COLOUR_RED, fields]


  @countAuthors = (revisions) ->
    authors = {}
    for revision in revisions
      authors[revision.author] = true
    Object.keys(authors).length

  @countEditTypes = (revisions) ->
    edits = {}
    for revision in revisions
      for file in revision.files
        edits[file.type] ?= 0
        edits[file.type]++
    return edits

  @formatChangeLog = (revisions) ->
    fields = []
    str = ""
    for revision in revisions
      url = GIT_URL + revision.node
      msg = @replaceTickets(revision.message)
      author = revision.raw_author.match /[^<]*/
      str += "<#{url}|#{author}>: #{msg}\n"
      if str.length > @MAX_MESSAGE_LENGTH
        fields.push str
        str = ""
    if str.length
      fields.push str
    return fields

  @replaceTickets = (msg) ->
    return msg.replace TICKET_PATTERN, (match) ->
      return "<" + TICKET_URL + match + "|" + match + ">"


  @extractClassname = (str) ->
    arr = str.split '.'
    return arr[arr.length - 1]

  @buildTestCasesStr = (cases) ->
    output = ""
    for suiteCase, i in cases
      idx = i + 1
      output += "*" + extractClassname(suiteCase.className) + "." + suiteCase.name + "*\n"
      output += "`" + suiteCase.errorDetails + "`\n" if suiteCase.errorDetails?
      remainingCases = (cases.count - idx)
      return output += "_and #{remainingCases} other tests_" if output.length > @MAX_MESSAGE_LENGTH and remainingCases
    return output


  @buildTestResults = (job, data, callback) ->
    regression = []
    fixed = []
    for suite in data.suites
      for suiteCase in suite.cases
        regression.push suiteCase if suiteCase.status.match /regression/i
        fixed.push suiteCase if suiteCase.status.match /fixed/i
    return callback "No test result data to show" if (!regression.length and !fixed.length) or !data.failCount
    attachments = []
    fields = []
    fields.push buildGroup "Passed", data.passCount, true if data.passCount
    fields.push buildGroup "Failed", data.failCount, true if data.failCount
    fields.push buildGroup "Skipped", data.skipCount, true if data.skipCount
    fields.push buildGroup "Duration", data.duration, true if data.duration
    attachments = @slack.buildAttachement("Test results", @COLOUR_YELLOW, fields)
    attachments.push @slack.buildAttachement(
      "", @COLOUR_GREEN, @slack.buildGroup "Fixed", (@buildTestCasesStr fixed), false
    ) if fixed.length

    attachments.push @slack.buildAttachement(
      "", @COLOUR_GREEN, @slack.buildGroup "Regression", (@buildTestCasesStr regression), false
    ) if regression.length

    msg = "<#{job.url}|#{job.fullDisplayName}>"
    callback null, msg, attachments

  @flatten = (object) ->
    res = {}
    for own key, value of object
      if (typeof value) is "object"
        flat = @flatten(value)
        for own flatKey, flatValue of flat
          res[key + "__" + flatKey] = flatValue
      else
        res[key] = value
    res