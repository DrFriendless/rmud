# types of messages that go into the event loop

class LoginMessage
  def initialize(username)
    @username = username
  end

  attr_reader :username
end


class CommandMessage
  def initialize(command)
    @command = command
  end

  attr_reader :command
  attr_accessor :body
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
  attr_accessor :quit
  attr_accessor :message
  attr_accessor :body

  def debug(key)
    "debug <#{key}> Quit <#{@quit}> handled <#{@handled}> message <#{@message}>"
  end
end
