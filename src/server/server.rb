#!/usr/bin/env ruby

require 'eventmachine'
require 'em-http-server'
require 'websocket-eventmachine-server'
require 'yaml'
require 'json'
require_relative './world.rb'
require_relative './events.rb'
require_relative './database.rb'
require_relative '../shared/messages.rb'

# the main event loop in the server
class EventLoop
  def initialize(world, database)
    @world = world
    @database = database
    @queue = EM::Queue.new
    callback = Proc.new do |e|
      e.reply(handle_event(e.message))
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
  def handle_event(event)
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
      @world.heartbeat
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
    # queue to send things back to the client.
    @queue = EM::Queue.new
    callback = Proc.new do |obj|
      send_data YAML::dump(obj)
      if obj.quit
        close_connection_after_writing
      end
      @queue.pop &callback
    end
    @queue.pop &callback
  end

  def receive_data(event)
    e = YAML::load(event)
    if e.is_a? CommandMessage
      e.body = @body
      EventLoop::enqueue(CommandEvent.new(e, self))
    else
      EventLoop::enqueue(LoginEvent.new(e, self))
    end
  end

  def reply(response)
    if response.handled
      if response.body
        @body = response.body
        @body.effect_callback = self
        # don't try to send the body back to the client
        response.body = ()
      end
      response.message ||= "<%= color('OK', BOLD) %>"
      if response.message
        @queue.push response
      end
    else
      response.message = "Computer says NO"
      @queue.push response
    end
  end

  def effect(effect)
    @queue.push(effect)
  end
end

class HTTPHandler < EM::HttpServer::Server
  def process_http_request
    #puts  @http_request_method
    puts  @http_request_uri
    #puts  @http_query_string
    #puts  @http_protocol
    #puts  @http_content
    #puts  @http[:cookie]
    #puts  @http[:content_type]
    # you have all the http headers in this hash
    #puts  @http.inspect

    if @http_request_uri == "/"
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/html'
      response.content = File.open("content/html/client.html", "r").read
      response.send_response
    else
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 404
      response.send_response
    end
  end

  def http_request_errback e
    # printing the whole exception
    puts e.inspect
  end
end

def decode_json(json)
  j = JSON.parse(json)
  if j["type"] == "login"
    return LoginMessage.new(j["username"], j["password"])
  else
    return CommandMessage.new(j["command"])
  end
end

class WebSocketController
  def initialize(ws)
    @ws = ws
    @body = ()
    ws.onopen do
      puts "Websocket Client connected #{ws}"
    end

    ws.onmessage do |msg, type|
      puts "Websocket Received message: #{msg} #{type} #{ws}"
      message = decode_json(msg)
      if message.is_a? LoginMessage
        event = LoginEvent.new(message, self)
      else
        message.body = @body
        event = CommandEvent.new(message, self)
      end
      EventLoop::enqueue(event)
    end

    ws.onclose do
      puts "Websocket Client disconnected #{ws}"
    end
  end

  def reply(response)
    if response.body; @body = response.body end
    @ws.send(response.to_json())
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
  WebSocket::EventMachine::Server.start(:host => "0.0.0.0", :port => 8079) { |ws| WebSocketController.new(ws) }
  puts 'websocket running on 8079'
  EM::start_server("0.0.0.0", 8080, HTTPHandler)
  puts 'httpd running on 8080'
  EventMachine::start_server "0.0.0.0", 8081, ClientHandler
  puts 'running server on 8081'
}