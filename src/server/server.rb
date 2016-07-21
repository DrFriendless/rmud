#!/usr/bin/env ruby

require 'eventmachine'
require 'yaml'
require_relative './world.rb'
require_relative './database.rb'
require_relative '../shared/messages.rb'

# Events are things which go on the event queue.

# a command from a body
class CommandEvent
  def initialize(message, body, callback)
    @message = message
    @body = body
    @callback = callback
  end

  attr_reader :message
  attr_reader :body

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
    puts "badoom"
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

# the main event loop in the server
class EventLoop
  def initialize(world, database)
    @world = world
    @database = database
    @queue = EM::Queue.new
    callback = Proc.new do |e|
      e.reply(handleMessage(e.message))
      @queue.pop &callback
    end
    @queue.pop &callback
  end

  def enqueue(e)
    @queue.push(e)
  end

  def find_handlers(body)
    result = [ body ] + body.contents
    if body.location
      result.push(body.location)
      result += body.location.contents
    end
    result
  end

# a command came from a client, execute its effect on the world.
  def handle_command(command)
    handlers = find_handlers(command.body)
    response = Response.new
    handlers.each { |h|
      h.handle(response, command)
      if response.handled; return response end
    }
    response
  end

# a message arrived, execute it
  def handleMessage(event)
    if event.is_a? CommandMessage
      return handle_command(event)
    elsif event.is_a? LoginMessage
      player_data = @database.check_password(event.username, event.password)
      if player_data
        puts "#{player_data[:username]} logs in"
        body = @world.find_player(event.username)
        if !body; body = @world.instantiate_player(event.username) end
        body.location ||= @world.find_singleton(body.loc)
        body.location ||= @world.find_singleton("lib/Room/lostandfound")
        body.move_to(body.location)
        response = Response.new
        response.handled = true
        response.message = body.location.long
        response.body = body
        return response
      else
        response = Response.new
        response.handled = true
        response.message = "Incorrect password"
        response.quit = true
        return response
      end
    elsif event.is_a? HeartbeatMessage
      # TODO
      return ()
    elsif event.is_a? PersistMessage
      return @world.persist
    else
      puts "Unhandled event #{event}"
      Response.new
    end
  end

  def self.create(world, database)
    @@event_loop = EventLoop.new(world, database)
  end

  def self.enqueue(event)
    @@event_loop.enqueue(event)
  end
end

# one of these exists for each client
module ClientHandler
  def post_init
  end

  def receive_data(event)
    e = YAML::load(event)
    if e.is_a? CommandMessage
      e.body = @body
    end
    EventLoop::enqueue(CommandEvent.new(e, @body, self))
  end

  def reply(response)
    if response.handled
      if response.body
        @body = response.body
        # don't try to send the body back to the client
        response.body = ()
      end
      response.message ||= "<%= color('OK', BOLD) %>"
      if response.message
        send_data YAML::dump(response)
      end
    else
      response.message = "Computer says NO"
      send_data YAML::dump(response)
    end
    if response.quit
      close_connection_after_writing
    end
  end
end

database = Database.new
world = World.new(database)
world.load()
EventLoop::create(world, database)
EventMachine::run {
  heartbeat_timer = EventMachine::PeriodicTimer.new(2) do
    EventLoop::enqueue(HeartbeatEvent.new)
  end
  persist_timer = EventMachine::PeriodicTimer.new(13) do
    EventLoop::enqueue(PersistEvent.new)
  end
  EventMachine::start_server "127.0.0.1", 8081, ClientHandler
  puts 'running server on 8081'
}