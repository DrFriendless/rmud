# types of messages that go into the event loop

class LoginMessage
  def initialize(username, password)
    @username = username
    @password = password
  end

  attr_reader :username
  attr_reader :password
end


class CommandMessage
  def initialize(command)
    @command = command
  end

  attr_reader :command
  attr_accessor :body

  def words()
    @command.split(' ')
  end
end


class HeartbeatMessage
end


class PersistMessage
end


# a response from the game on what happened due to an event
class Response
  @quit = false
  @handled = false
  @message = ()
  @body = ()

  attr_accessor :handled
  attr_accessor :direction
  attr_accessor :quit
  attr_accessor :message
  attr_accessor :body

  def to_json()
    return JSON.generate({"message" => @message})
  end
end
