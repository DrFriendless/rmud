require 'highline'

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

class DefaultHandler
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
  [ DefaultHandler.new ]
end

def handle(command)
  handlers = find_handlers
  response = Response.new
  for h in handlers
    h.handle(response, command)
    if response.was_handled
      return response
    end
  end
  response
end

class Repl
  def run
    cli = HighLine.new
    loop do
      command = cli.ask "> "
      response = handle(command)
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