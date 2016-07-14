#!/usr/bin/env ruby
#
# Stolen from the eventmachine documentation.

require 'eventmachine'
require 'highline'

class Echo < EM::Connection
  attr_reader :queue
  attr_reader :cli

  def initialize(q)
    @cli = HighLine.new
    @queue = q

    callback = Proc.new do |msg|
      send_data(msg)
      q.pop &callback
    end

    q.pop &callback
  end

  def post_init
    send_data('Hello')
    prompt
  end

  def prompt
    @cli.say "> "
  end

  def receive_data(data)
    @cli.say data
  end

  def unbind
    EventMachine::stop_event_loop
  end
end

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  attr_reader :queue

  def initialize(q)
    @queue = q
  end

  def receive_line(data)
    @queue.push(data)
  end
end

EM.run {
  q = EM::Queue.new

  EM.connect('127.0.0.1', 8081, Echo, q)
  EM.open_keyboard(KeyboardHandler, q)
}