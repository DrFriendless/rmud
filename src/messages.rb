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

  def handle()
    @handled = true
  end

  def quit()
    @quit = true
  end

  def message(s)
    @message = s
  end

  def get_message()
    @message
  end

  def was_handled()
    @handled
  end

  def should_quit()
    @quit
  end

  def debug(key)
    "debug <#{key}> Quit <#{@quit}> handled <#{@handled}> message <#{@message}>"
  end
end
