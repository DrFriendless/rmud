#!/usr/bin/env ruby

require 'eventmachine'
require './repl.rb'

module PlayerServer
  def post_init
    puts "-- someone connected to the echo server! #{object_id}"
  end

  def receive_data command
    puts "message from #{object_id}"
    response = handle(command)
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
  EventMachine::start_server "127.0.0.1", 8081, PlayerServer
  puts 'running server on 8081'
}