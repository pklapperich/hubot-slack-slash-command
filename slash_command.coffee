# Description:
#   This script implements the slash command API as a hubot script
#
#   If you are at your slack integrations limit, but would like to add
#   a slack command integration, then this script is for you!
#
#   To use, 
#   1. Enable the slash command API and create a caommnd and get your API token
#     Once you have your API token you may disable any slash commands you created.
#     Disabled commands don't count towards your integrations limit. Doing this, 
#     will ensure the API token is unique to you.
#
#   2. Set the SLASH_TOKEN environment variable and set it to your slash token
#
#   3. Edit the COMMANDS dictionary below to add your commands
#      command: [DM?, URL, error if not authorized]
#      command - the name of the command and also the name of the hubot-auth role required
#      DM? - 0 to reply in channel, 1 to reply with a direct message
#      URL - the URL to post the slash-command to
#      error - the response text 
#
#   4. Install and configure hubot-auth from https://github.com/hubot-scripts/hubot-auth
#      NOTE: on slack, hubot-auth uses user IDs, not user names to define admins.
#      you can get the user IDs required for the HUBOT_AUTH_ADMIN setting by calling the users.list API method.
#      from https://api.slack.com/methods/users.list/test
#
#   5. Place your customized slash_command.coffee in your scripts/ folder and restart your hubot
qs = require 'querystring'


COMMANDS = { 
   #command: [DM?, URL, response if not authorized]
   'code': [0, 'http://example.com/code', 'submit codes to example']
   }

slash_token = process.env.SLASH_TOKEN

module.exports = (robot) ->

   #robot.hear /(.*)/i, (msg) -> # this hears everything

   #respond to any "hubot command some text" or "hubot command"
   robot.respond /(.*?) (.*)|([^\s]*)/i, (msg) ->
     #console.log msg.send.toString()
     username = msg.message.user.name

     if msg.match[3] != undefined  #command has no text
       slash_cmd = msg.match[3]
       slash_text = ''
     else
       slash_cmd  = msg.match[1]
       slash_text = msg.match[2]

     for command, output of COMMANDS
       if command == slash_cmd.toLowerCase()
         console.log "processing " + slash_cmd + ", text is " + slash_text
         #set the envelope to the username for DM
         msg.envelope.room = username if output[0]
         url = output[1]
         response = output[2]
         if robot.auth.hasRole(msg.envelope.user,slash_cmd)
           channel = msg.message.channel
           debugger
           room = msg.message.user.room
           data = qs.stringify({
              'token': slash_token,
              'team_id': msg.message.rawMessage.team,
              'team_domain': robot.adapter.client.team.domain,
              'channel_id': msg.message.rawMessage.channel,
              'channel_name': room,
              'user_id': msg.message.user.id,
              'user_name': username,
              'command':'/' + slash_cmd,
              'text': slash_text
              })

           console.log "posting " + data + " to " + url
           x = msg.http(url)
               .post(data) (err, res, body) ->
                 if err
                   msg.send "Error: #{err}"
                   return
                 if res.statusCode isnt 200
                   msg.send "Post failed"
                   return
                 msg.send body
         else
           response = "use this command" if response == ''
           msg.send "You must have the <" +slash_cmd+ "> role to " + response
