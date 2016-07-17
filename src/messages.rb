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