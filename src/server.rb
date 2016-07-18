#!/usr/bin/env ruby

require 'eventmachine'
require 'yaml'
require_relative './repl.rb'
require_relative './world.rb'
require_relative './database.rb'

# an event on the event queue
class Event
  def initialize(event, handler)
    @event = event
    @handler = handler
  end

  attr_reader :event
  attr_reader :handler
end

# a heartbeat message and a null callback
class HeartbeatEvent < Event
  def initialize()
    @event = HeartbeatMessage.new
    @handler = self
  end

  def reply(response)
    puts "badoom"
  end
end

# a persist message and a null callback
class PersistEvent < Event
  def initialize()
    @event = PersistMessage.new
    @handler = self
  end

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
      e.handler.reply(handleEvent(e.event))
      @queue.pop &callback
    end
    @queue.pop &callback
  end

  def enqueue(e)
    @queue.push(e)
  end

  # an event arrived, execute it
  def handleEvent(event)
    if event.is_a? CommandMessage
      return handleCommand event.command
    elsif event.is_a? LoginMessage
      puts "#{event.username} logs in"
      response = Response.new
      response.handle
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
    EventLoop::enqueue(Event.new(e, self))
  end

  def reply(response)
    if response.should_quit
      close_connection_after_writing
    end
    if response.was_handled
      message = response.get_message
      if message
        send_data message
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
  p data
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