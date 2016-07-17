require 'highline'
require_relative './messages'

class DefaultCommandHandler
  def handle(response, command)
    if command == "quit"
      puts "Command #{command}"
      response.handle
      response.quit
    end
    if command == "yes"
      response.handle
      response.message "Computer says YES"
    elsif command == "no"
      response.handle
    end
  end
end

def find_handlers()
  [ DefaultCommandHandler.new ]
end

# a command came from a client, execute its effect on the world.
def handleCommand(command)
  handlers = find_handlers
  response = Response.new
  for h in handlers
    h.handle(response, command)
    if response.was_handled
      break
    end
  end
  response
end

