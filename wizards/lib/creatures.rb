require 'eventmachine'
require_relative './bodies.rb'
require_relative '../../src/shared/messages.rb'
require_relative '../../src/server/events.rb'

class Creature < Body
  def initialize
    super
    @queue = EM::Queue.new
  end

  def command(s)
    @queue.push(s)
  end

  def heartbeat(time, time_of_day)
    if !@queue.empty?
      @queue.pop { |command|
        if command == 'extend'
          extend_path
        else
          msg = CommandMessage.new(command)
          msg.body = self
          event = CommandEvent.new(msg, self)
          EventLoop::enqueue(event)
        end
      }
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
    if @path
      extend_path
    end
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

  def name
    short
  end
end

class SingletonCreature < Creature
  include Singleton
end