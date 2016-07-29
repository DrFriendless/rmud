# Events are things which go on the event queue.

# a command from a body
class CommandEvent
  def initialize(message, callback)
    @message = message
    @callback = callback
  end

  attr_reader :message

  def reply(response)
    @callback.reply(response)
  end
end

# a command from a body
class LoginEvent
  def initialize(message, callback)
    @message = message
    @callback = callback
  end

  attr_reader :message

  def reply(response)
    @callback.reply(response)
  end
end

# a heartbeat message and a null callback
class HeartbeatEvent
  def initialize()
    @message = HeartbeatMessage.new
    @handler = self
  end

  attr_reader :message

  def reply(response)
  end
end

# a persist message and a null callback
class PersistEvent
  def initialize()
    @message = PersistMessage.new
    @handler = self
  end

  attr_reader :message

  def reply(data)
    puts "saved"
  end
end

# a reset message and a null callback
class ResetEvent
  def initialize()
    @message = ResetMessage.new
    @handler = self
  end

  attr_reader :message

  def reply(data)
    puts "reset"
  end
end
