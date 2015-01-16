
async = require('async')
Util = require "util"
qs = require("querystring")

checkoutPattern = /prodco/i
unitTestPattern = /unittest/i
deploymentPattern = /deploy/i

PHASE_COMPLETED = /completed/i

JOB_QUERY_STR = "api/json?tree=actions[causes[shortDescription,userId,userName]],changeSet[kind,revisions[module,revision],items[commitId[fullName]]],building,duration,fullDisplayName,id,number,result,timestamp,url&pretty'"

GIT_URL = process.env.HUBOT_JENKINS_GIT_URL
TICKET_URL = process.env.HUBOT_JENKINS_ISSUE_TRACKING_URL

TICKET_PATTERN = new RegExp process.env.HUBOT_JENKINS_TICKET_PATTERN, 'gi'

SLACK_API_TOKEN = process.env.HUBOT_SLACK_API_TOKEN
SLACK_CHANNEL_ID = process.env.HUBOT_JENKINS_RELEASE_SLACK_CHANNEL

jenkinsDomain = process.env.HUBOT_JENKINS_DOMAIN
JENKINS_READ_USERNAME = process.env.HUBOT_JENKINS_READ_USERNAME
JENKINS_READ_TOKEN = process.env.HUBOT_JENKINS_READ_TOKEN

JENKINS_ICON = process.env.HUBOT_JENKINS_RELEASE_SLACK_ICON

BITBUCKET_API_URL = process.env.HUBOT_BITBUCKET_API_URL
BITBUCKET_API_USERNAME = process.env.HUBOT_BITBUCKET_API_USERNAME
BITBUCKET_API_PASSWORD = process.env.HUBOT_BITBUCKET_API_PASSWORD

fails = require '../data/fail.json'
success = require '../data/success.json'

module.exports = (robot) ->

  robot.router.post '/jenkins/receive', (req, res) ->
    data   = req.body
    res.send 'OK'
    name = data.name
    handleCheckout data if name.match checkoutPattern
    handleUnitTest data if name.match unitTestPattern
    handleDeployment data if name.match deploymentPattern

  checkBuildPhaseCompleted = (data, callback) ->
    if data.build.phase.match PHASE_COMPLETED
      console.log "Match found"
      callback null, data
    return (callback) ->
      callback "No match"

  handleCheckout = (data) ->
    composition = async.seq(
      checkBuildPhaseCompleted,
      getJobInfoFromApi,
      fetchBitbucketChangeset,
      buildChangelog
      postToSlack
    )

    composition data, (err, result) ->
      console.log err if err
      console.log result if result


#    getJobInfoFromApi  data, (err, data) ->
#      fetchBitbucketChangeset  data, (err, data) ->
#        buildChangelog  data, (err, data) ->
#          postToSlack data, (err, data) ->


  getJobInfoFromApi = (data, callback) ->
    url = "https://" + jenkinsDomain + "/job/" + data.name + "/" + 1921 + "/" + JOB_QUERY_STR
    console.log "Calling URL #{url}"
    robot.http(url)
    .auth(JENKINS_READ_USERNAME, JENKINS_READ_TOKEN)
    .get() (err, resp, body) ->
      return callback err if err
      console.log "JenkinsJob #{body}"
      callback null, JSON.parse body

  fetchBitbucketChangeset = (job, callback) ->
    console.log "fetchBitbucketChangeset" + Util.inspect job
    tasks = []
    for change in job.changeSet.items
      do (change) ->
        tasks.push (taskCallback) ->
          robot.http(BITBUCKET_API_URL + change.commitId)
          .auth(BITBUCKET_API_USERNAME, BITBUCKET_API_PASSWORD)
          .get() (err, resp, body) ->
            taskCallback err, JSON.parse(body)
            console.log "BitBucket node #{body}"
    async.parallelLimit tasks, 10, callback


  handleUnitTest = (data) ->
    robot

  handleDeployment = (data) ->
    robot


  buildChangelog = (revisions, callback) ->
    console.log "buildChangeLog " + Util.inspect revisions
    fields = []
    fields.push buildGroup 'Revisions', revisions.length, true
    fields.push buildGroup 'Authors', countAuthors(revisions), true
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
      fields.push buildGroup(title, logGroup, false)
    callback null, "Release test", [{'text': "Groups", 'color': "#94c22f", 'fields': fields}]


  buildGroup = (title, value, short) ->
    return {'title': "#{title}", 'value': "#{value}", 'short': short }

  countAuthors = (revisions) ->
    authors = {}
    for revision in revisions
      authors[revision.author] = true
    Object.keys(authors).length

  countEditTypes = (revisions) ->
    edits = {}
    for revision in revisions
      for file in revision.files
        edits[file.type] ?= 0
        edits[file.type]++
    return edits

  formatChangeLog = (revisions) ->
    fields = []
    str = ""
    for revision in revisions
      url = GIT_URL + revision.node
      msg = replaceTickets(revision.message)
      author = revision.raw_author.match /[^<]*/
      str += "<#{url}|#{author}>: #{msg}\n"
      if str.length > 2000
        fields.push str
        str = ""
    if str.length
      fields.push str
    return fields

  replaceTickets = (msg) ->
    return msg.replace TICKET_PATTERN, (match) ->
      return "<" + TICKET_URL + match + "|" + match + ">"

  postToSlack = (msg, attachments, callback) ->
    fields = {
      'text': msg,
      'token': SLACK_API_TOKEN,
      'channel': SLACK_CHANNEL_ID,
      'username': "Jenkins",
      'icon_url': JENKINS_ICON
    }
    if attachments
      fields['attachments'] = JSON.stringify(attachments)
    console.log Util.inspect fields
    robot.http("https://slack.com/api/chat.postMessage")
    .header('Content-type', 'application/x-www-form-urlencoded')
    .post(qs.stringify(fields)) callback