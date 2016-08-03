# types of messages that go into the event loop

class LoginMessage
  def initialize(username, password)
    @username = username
    @password = password
  end

  attr_reader :username
  attr_reader :password

  def to_json
    "{\"type\": \"login\", \"username\": \"#{@username}\", \"password\": \"#{@password}\"}"
  end
end


class CommandMessage
  def initialize(command)
    @command = command
  end

  attr_accessor :command
  attr_accessor :body
  attr_accessor :say

  def words
    @command.split(' ')
  end

  def room
    @body.location
  end
end


class HeartbeatMessage
end


class PersistMessage
end


class ResetMessage
end


# a response from the game on what happened due to an event
class Response
  def initialize
    @quit = false
    @handled = false
    @message = nil
    @body = nil
    @command = nil
  end

  attr_accessor :handled
  attr_accessor :direction
  attr_accessor :quit
  attr_accessor :message
  attr_accessor :body
  attr_accessor :command

  def to_s
    @message
  end

  def to_json
    JSON.generate({'message' => @message})
  end
end
