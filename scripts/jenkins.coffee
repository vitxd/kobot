# Description:
#   Urban dictionary
#
# Commands:
#   hubot release the kraken - Triggers a production release
#   hubot jenkins build [job name] - Triggers a job with name
#   hubot jenkins whoami - Returns your linked Jenkins user
#   hubot jenkins token set [Jenkins token] - Sets your API token
#   hubot jenkins token show - Returns your API token
#
#
# Author:
#   h.deakin@quidco.com

jenkinsDomain = process.env.JENKINS_DOMAIN
jenkinsReleaseView = process.env.JENKINS_RELEASE_VIEW

API = '/api/json?pretty=true'

JenkinsApi = require "jenkins-api"

Util = require "util"

module.exports = (robot) ->
  getConfig = ()->
    return robot.brain.data.jenkins ||= []

  getUsername = (msg) ->
    return msg.message.user.email_address

  setAuthToken = (msg, token) ->
    config = getConfig()
    config[getUsername(msg)] = token
    robot.brain.data.jenkins = config

  getAuthToken = (msg) ->
    config = getConfig()
    return config[getUsername(msg)]

  jenkinsApi = (method, msg, path, next) ->
    pass = getAuthToken(msg)
    username = getUsername(msg)
    if (pass == null)
      return msg.send "@" + msg.message.user.name + " DENIED!"
    url = "https://" + username + ":" + pass + "@" + jenkinsDomain + "/" + path + API
    robot.http(url)[method]() (err, res, body) ->
      console.log Util.inspect(res)
      if err
        return msg.send "Encountered an error :( #{err}"
      if res.statusCode != 200 && res.statusCode != 201
        return msg.send "Encountered HTTP status " + res.statusCode
      response = null
      if body
        response = JSON.parse(body)
      if (next)
        next msg, response

  checkViewIsNotExecuting = (msg, view, next) ->
    for key, job of view.jobs
      if job.color.match(/_anime/i)
        return msg.send job.name + " is already running"
    next msg, view

  getUser = (msg) ->
    jenkinsApi('get', msg, "user/" + getUsername(msg), (msg, response) ->
      msg.send "@" + msg.message.user.name + " you're linked to Jenkins user " + response.fullName
    )

  robot.respond /jenkins whoami/i, (msg) ->
    getUser(msg)

  robot.respond /jenkins token set (.+)/i, (msg) ->
    pass = msg.match[1]
    setAuthToken(msg, pass)
    getUser(msg)

  robot.respond /jenkins token show/i, (msg) ->
    token = getAuthToken(msg) || "Denied!"
    return msg.send "@" + msg.message.user.name + " " + token

  robot.respond /release the kraken/i, (msg) ->
    jenkinsApi "get", msg, "view/" + jenkinsReleaseView, (msg, response) ->
    checkViewIsNotExecuting msg, response, (msg, view) ->
    jobName = view.jobs[0].name
    jenkinsApi 'post', msg, "job/" + jobName + "/build", (msg, response) ->
    return msg.send jobName + " now running"

  robot.respond /jenkins build (.+)/i, (msg) ->
    job = msg.match[1]
    jenkinsApi 'post', msg, "job/" + jobName + "/build", (msg, response) ->
    return msg.send jobName + " now running"

#    robot.respond /unreleased commits/i (msg) ->
#      return msg.send
