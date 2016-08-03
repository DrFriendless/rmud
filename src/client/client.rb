#!/usr/bin/env ruby
#
# Stolen from the eventmachine documentation.

require 'eventmachine'
require 'highline'
require 'yaml'
require 'json'
require_relative '../shared/messages'
require_relative '../shared/effects'

class RmudClient < EM::Connection
  def initialize(q, player, password)
    @queue = q
    @player = player
    @password = password
    @cli = HighLine.new

    callback = Proc.new do |msg|
      send_message(CommandMessage.new msg)
      q.pop &callback
    end

    q.pop &callback
  end

  def send_message(msg)
    send_data(msg.to_json)
  end

  def post_init
    send_message(LoginMessage.new(@player,@password))
    prompt
  end

  def prompt
    @cli.say "> "
  end

  def receive_data(data)
    data.split("<DIV>").select { |s| s.length > 0 }.each { |d|
      @cli.say(JSON.parse(d)['message'])
    }
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
    if data.size > 0
      @queue.push(data)
    end
  end
end

if ARGV.size == 0
  puts "You need to give a profile name on the command line."
end
profile = ARGV[0]
yaml = Psych.load_file("client.yml")
if yaml[profile]
  host = yaml[profile]["host"]
  port = yaml[profile]["port"].to_i
  player = yaml[profile]["user"]
  password = yaml[profile]["password"]
  EM.run {
    q = EM::Queue.new
    EM.connect(host, port, RmudClient, q, player, password)
    EM.open_keyboard(KeyboardHandler, q)
  }
else
  puts "Profile '#{profile}' not defined in client.yml."
end
