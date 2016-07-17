#!/usr/bin/env ruby
#
# Stolen from the eventmachine documentation.

require 'eventmachine'
require 'highline'
require 'yaml'
require_relative './messages'

class RmudClient < EM::Connection
  def initialize(q)
    @cli = HighLine.new
    @queue = q

    callback = Proc.new do |msg|
      send_message(CommandMessage.new msg)
      q.pop &callback
    end

    q.pop &callback
  end

  def send_message(msg)
    send_data(YAML::dump(msg))
  end

  def post_init
    # TODO - send user name and client type identification
    @username = "Hello"
    send_message(LoginMessage.new @username)
    prompt
  end

  def prompt
    @cli.say "> "
  end

  def receive_data(data)
    @cli.say data
    prompt
  end

  def unbind
    # disconnected from the server
    EventMachine::stop_event_loop
  end
end

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  def initialize(q)
    @queue = q
  end

  def receive_line(data)
    @queue.push(data)
  end
end

EM.run {
  q = EM::Queue.new
  EM.connect('127.0.0.1', 8081, RmudClient, q)
  EM.open_keyboard(KeyboardHandler, q)
}