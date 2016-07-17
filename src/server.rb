#!/usr/bin/env ruby

require 'eventmachine'
require 'yaml'
require './repl.rb'

class Event
  def initialize(event, handler)
    @event = event
    @handler = handler
  end

  attr_reader :event
  attr_reader :handler
end

class EventQueue
  def initialize()
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

  @@event_queue = EventQueue.new

  def self.enqueue(event)
    @@event_queue.enqueue(event)
  end
end

module EventHandler
  def post_init
    puts "-- someone connected to the server! #{object_id}"
  end

  def receive_data(event)
    e = YAML::load(event)
    puts "-- message from #{object_id} #{e}"
    EventQueue::enqueue(Event.new(e, self))
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

EventMachine::run {
  EventMachine::start_server "127.0.0.1", 8081, EventHandler
  puts 'running server on 8081'
}