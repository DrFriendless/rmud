#!/usr/bin/env ruby

require 'eventmachine'
require 'yaml'
require_relative './world.rb'
require_relative './database.rb'
require_relative './messages.rb'

class DefaultCommandHandler
  def handle(response, command)
    if command == "quit"
      response.handled = true
      response.quit = true
    end
  end
end

# an event on the event queue
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
    Database::persist(data)
  end
end

# the main event loop in the server
class EventLoop
  def initialize(world)
    @world = world
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
    result = [ body ]
    if body.location
      result.push(body.location)
    end
    result.push DefaultCommandHandler.new
  end

# a command came from a client, execute its effect on the world.
  def handleCommand(command, body)
    handlers = find_handlers(body)
    response = Response.new
    for h in handlers
      h.handle(response, command)
      if response.handled
        break
      end
    end
    response
  end

  # a message arrived, execute it
  def handleMessage(event)
    if event.is_a? CommandMessage
      return handleCommand(event.command, event.body)
    elsif event.is_a? LoginMessage
      puts "#{event.username} logs in"
      body = @world.instantiate_player(event.username)
      body.move_to(@world.find_singleton("lib/Room/lostandfound"))
      response = Response.new
      response.handled = true
      response.message = body.location.long
      response.body = body
      return response
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

  def self.set_world(world)
    @@event_loop = EventLoop.new(world)
  end

  def self.enqueue(event)
    @@event_loop.enqueue(event)
  end
end

# one of these exists for each client
module ClientHandler
  def post_init
    puts "-- someone connected to the server! #{object_id}"
  end

  def receive_data(event)
    e = YAML::load(event)
    puts "-- message from #{object_id} #{e}"
    if e.is_a? CommandMessage
      e.body = @body
    end
    EventLoop::enqueue(CommandEvent.new(e, @body, self))
  end

  def reply(response)
    if response.quit
      close_connection_after_writing
    end
    if response.handled
      if response.body
        @body = response.body
      end
      if response.message
        send_data response.message
      else
        send_data "<%= color('OK', BOLD) %>"
      end
    else
      send_data "Computer says NO"
    end
  end
end

world = World.new
world.load_lib
data = Database::restore
if data.size == 0
  world.on_world_create
else
  world.restore(data)
end
EventLoop::set_world(world)
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