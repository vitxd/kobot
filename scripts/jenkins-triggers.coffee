# Description:
#   Jenkins Triggers
#
# Commands:
#   hubot add jenkins listener where foo=bar - Listen for jobs
#
#
# Author:
#   h.deakin@quidco.com


async = require('async')
Util = require "util"
qs = require("querystring")



matches = {
  "x-foo-bar-tests": [
    {
      "name": "prodco",
      "build.phase": "started"
    },
    {
      "name": "QG2-UnitTests|MobAppTest-Staging|DeployProd",
      "build.phase": "finished",
      "build.status": "success"
    },
    {
      "name": "Prod-Q|MobAppTest-Staging|prodco",
      "build.phase": "finished",
      "build.status": "failure"
    },
    {
      "name": "Prod-Q|MobAppTest-Staging|prodco",
      "build.phase": "aborted"
    }
  ],
}

# add jenkins listener where name=prodco, build.phase=started
# add jenkins listener where name="QG2-UnitTests|MobAppTest-Staging|DeployProd", build.phase=finished, build.status=success
# add jenkins listener where name="Prod-Q|MobAppTest-S|prodco", build.phase=finished, build.status=failure
# add jenkins listener where name="Prod-Q|MobAppTest-S|prodco", build.phase=aborted


GIT_URL = process.env.HUBOT_JENKINS_GIT_URL
TICKET_URL = process.env.HUBOT_JENKINS_ISSUE_TRACKING_URL

TICKET_PATTERN = new RegExp process.env.HUBOT_JENKINS_TICKET_PATTERN, 'gi'

JENKINS_DOMAIN = process.env.HUBOT_JENKINS_DOMAIN
JENKINS_READ_USERNAME = process.env.HUBOT_JENKINS_READ_USERNAME
JENKINS_READ_TOKEN = process.env.HUBOT_JENKINS_READ_TOKEN

JENKINS_ICON = process.env.HUBOT_JENKINS_RELEASE_SLACK_ICON

BITBUCKET_API_URL = process.env.HUBOT_BITBUCKET_API_URL
BITBUCKET_API_USERNAME = process.env.HUBOT_BITBUCKET_API_USERNAME
BITBUCKET_API_PASSWORD = process.env.HUBOT_BITBUCKET_API_PASSWORD

fails = [] #require '../data/fail.json'


module.exports = (robot) ->

#  robot.router.post '/hubot/jenkins', (req, res) ->
  robot.router.post '/receive', (req, res) ->

    robot.http('http://localhost:8080/receive/?event=jenkins.build.live')
    .header('Content-type', 'application/json')
    .post(req.body.payload) (err, resp, body) ->
      echo err if err
    return

    data   = req.body
    res.send 'OK'
    name = data.name
    handleCheckout data if name.match checkoutPattern
    handleUnitTest data if name.match unitTestPattern
    handleDeployment data if name.match deploymentPattern

  checkBuildPhaseCompleted = (data, callback) ->
    if data.build.phase.match PHASE_COMPLETED
      console.log "Match found"
      callback null, data.name, data.name
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
    composition(data) (err, result) ->
      console.log err if err

  getJobInfoFromApi = (jobName, jobNumber, callback) ->
    url = "https://" + JENKINS_DOMAIN + "/job/" + jobName + "/" + jobNumber + "/" + JOB_QUERY_STR
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


  robot.respond /(?:new|add) jenkins listener where (.*?)$/i, (msg) ->
    handleNewJob robot, msg, msg.match[1], msg.match[2]


