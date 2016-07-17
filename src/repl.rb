require 'highline'
require_relative './messages'

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


def handleEvent(event)
  if event.is_a? CommandMessage
    return handleCommand event.command
  elsif event.is_a? LoginMessage
    puts "#{event.username} logs in"
    response = Response.new
    response.handle
    return response
  else
    puts "Unhandled event #{event}"
  end
  Response.new
end

class Repl
  def run
    cli = HighLine.new
    loop do
      command = cli.ask "> "
      response = handleCommand(command)
      if response.should_quit
        break
      end
      if response.was_handled
        message = response.get_message
        if message
          cli.say message
        else
          cli.say "<%= color('OK', BOLD) %>"
        end
      else
        cli.say "Computer says NO"
      end
    end
  end
end