require 'highline'
require_relative './messages'

class DefaultCommandHandler
  def handle(response, command)
    if command == "quit"
      puts "Command #{command}"
      response.handled = true
      response.quit = true
    end
    if command == "yes"
      response.handled = true
      response.message = "Computer says YES"
    elsif command == "no"
      response.handled = true
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
    if response.handled
      break
    end
  end
  response
end

