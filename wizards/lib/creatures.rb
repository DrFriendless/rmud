require 'eventmachine'
require_relative './bodies.rb'
require_relative '../../src/shared/messages.rb'
require_relative '../../src/server/events.rb'

class Creature < Body
  def initialize
    super
    @queue = EM::Queue.new
    @quickqueue = EM::Queue.new
    @pause = 0
    @fighting = nil
  end

  def quick_command(s)
    @quickqueue.push(s)
  end

  def command(s)
    @queue.push(s)
  end

  def do_command(command)
    if command == 'extend'
      extend_path
    else
      match = /pause (\d+)/.match(command)
      if match
        @pause = match[1].to_i
      else
        msg = CommandMessage.new(command)
        msg.body = self
        event = CommandEvent.new(msg, self)
        EventLoop::enqueue(event)
      end
    end
  end

  def heartbeat(time, time_of_day)
    if !@quickqueue.empty?
      @quickqueue.pop { |command| do_command(command) }
    elsif @pause > 0
      @pause -= 1
    elsif !@queue.empty?
      @queue.pop { |command| do_command(command) }
    end
  end

  def reply(response)
    if !response.handled
      p "#{short}: game doesn't understand '#{response.command}'"
    elsif response.message
      p "#{short}: #{response.message}"
    end
  end

  def after_properties_set
    super
    if @path; extend_path end
    if @chats; setup_chats end
    add_creature_verbs
  end

  def extend_path
    p = []
    @path.each { |s|
      if s == 'shuffle'
        p.shuffle
        p.each { |s| command(s) }
        p.clear
      else
        p.push(s)
      end
    }
    p.each { |s| command(s) }
  end

  def setup_chats
    @chat_table = []
    @chats.each { |ch|
      m = /(.*)=~(.*)/.match(ch)
      if m
        @chat_table.push(Chat.new(m[1].strip, m[2].strip))
      end
    }
  end

  def try_to_chat(actor, says)
    @chat_table.each { |ch|
      if ch.match(says)
        p ch.response
        resp = eval('"' + ch.response + '"', binding)
        quick_command("'#{resp}")
      end
    }
  end

  def effect(effect)
    if effect.is_a?(SayEffect) && effect.actor == self
      return
    end
    if @chats && effect.is_a?(SayEffect)
      try_to_chat(effect.actor, effect.says)
    end
  end

  def name
    short
  end
end

class Chat
  def initialize(pattern, response)
    @pattern = pattern.downcase
    @response = response
  end

  def match(s)
    /#{@pattern}/ =~ s.downcase
  end

  attr_reader :response
end

class SingletonCreature < Creature
  include Singleton
end