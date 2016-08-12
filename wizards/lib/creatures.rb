require 'eventmachine'
require_relative './body'
require_relative './soul'
require_relative '../../src/shared/messages'
require_relative '../../src/server/events'

# tricks creatures have that players don't
class CreatureSoul < Soul
  def after_properties_set
    super
    verb(["healself"]) { |response, command, match|
      command.body.heal(command.body.maxhp)
      response.handled = true
    }
  end
end

class Creature < Body
  def initialize
    super
    @queue = EM::Queue.new
    @quickqueue = EM::Queue.new
    @pause = 0
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
    return if super
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
    receive_into_container(world.create("lib/CreatureSoul/default"))
    if @path; extend_path end
    if @chats; setup_chats end
    create_initial_items
  end

  private def create_initial_items
    w = @weapon
    if w
      tcr = ThingClassRef.new(@thingClass.wizard, w)
      thing = world.instantiate_ref(tcr)
      if thing
        thing.move_to(self)
        quick_command("wield #{thing.short}")
      end
    end
    cs = @possessions
    if cs
      cs.split.each { |rs|
        if is_money?(rs)
          thing = world.instantiate_gold(rs)
          if thing; thing.move_to(self) end
        else
          tcr = ThingClassRef.new(@thingClass.wizard, rs)
          thing = world.instantiate_ref(tcr)
          if thing; thing.move_to(self) end
        end
      }
    end
  end

  private def extend_path
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

  private def setup_chats
    @chat_table = []
    @chats.each { |ch|
      m = /(.*)=~(.*)/.match(ch)
      if m
        @chat_table.push(Chat.new(m[1].strip, m[2].strip))
      end
    }
  end

  private def try_to_chat(actor, says)
    @chat_table.each { |ch|
      if ch.match(says)
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

  def you_died(killed_by)
    super
    self.destroy
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

class DamageResistance < Thing
  include Armour

  def mutate_attack(attack)
    attack.decrease(:piercing, self, @piercing, 1000000) if @piercing
    attack.decrease(:slashing, self, @slashing, 1000000) if @slashing
    attack.decrease(:bludgeoning, self, @bludgeoning, 1000000) if @bludgeoning
    attack.decrease(:fire, self, @fire, 1000000) if @fire
    attack.decrease(:cold, self, @cold, 1000000) if @cold
    attack.decrease(:electricity, self, @electricity, 1000000) if @electrcity
    attack.decrease(:acid, self, @acid, 1000000) if @acid
    attack.decrease(:poison, self, @poison, 1000000) if @poison
    attack.decrease(:necrotic, self, @necrotic, 1000000) if @necrotic
  end
end