require_relative '../../src/server/thingutil'
require_relative '../../src/server/thing'
require_relative '../../src/server/money'
require_relative './directions'

class Room < Thing
  include Container
  include Singleton
  include Directions

  def initialize
    super
    initialize_contents
    @lit = false
  end

  def after_properties_set
    super
    add_direction_verbs
    verb(["find", "quests"]) { |response,command,match|
      if command.body.is_a? PlayerBody
        if command.body.ghost?
          command.body.tell("Ghosts can't get quests.")
        else
          quest_keys = @quests.split
          count = 0
          quest_keys.each { |qk|
            key = world.dest(wizard, qk)
            unless command.body.has_quest(key)
              count += 1
              q = world.create(key)
              command.body.tell(q.description)
              command.body.tell("Use the command 'accept #{q.key}' to accept this quest.")
              q.destroy
            end
          }
          if count == 0
            command.body.tell("There are no more quests available here for you.")
          end
        end
        response.handled = true
      end
    }
    verb(["accept", :word]) { |response,command,match|
      if command.body.is_a? PlayerBody
        if command.body.ghost?
          command.body.tell("Ghosts can't get quests.")
        else
          quest_keys = @quests.split
          quest_keys.each { |qk|
            key = world.dest(wizard, qk)
            if command.body.has_quest(key)
              command.body.tell("You cannot accept that quest again.")
            else
              q = world.create(key)
              q.move_to(command.body)
            end
          }
        end
      end
      response.handled = true
    }
  end

  def publish_to_room(effect)
    @contents.each { |c| c.effect(effect) }
  end

  def persist(data)
    super
    persist_contents(data)
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
  end

  def on_world_create
  end

  def carriable?
    false
  end

  def lit?
    (@lit == true) ||
        (@lit == "true") ||
        (@contents.any? { |thing| thing.lightsource? })
  end

  def reset
    cs = @contains
    if cs
      cs.split.each { |rs|
        if is_money?(rs)
          tcr = ThingClassRef.new(nil, "lib/Gold/default")
          unless find_by_class(tcr)
            thing = world.instantiate_gold(rs)
            if thing; thing.move_to(self) end
          end
        else
          tcr = ThingClassRef.new(wizard, rs)
          p tcr.to_s
          if tcr.singleton?
            thing = world.find_singleton(tcr.key)
            if !thing
              thing = world.instantiate_ref(tcr)
              if thing; thing.move_to(self) end
            elsif thing.location
              p "#{thing.short} is found at #{thing.location.short}" if thing.short
            else
              thing.move_to(self)
            end
          elsif !find_by_class(tcr)
            thing = world.instantiate_ref(tcr)
            if thing; thing.move_to(self) end
          end
        end
      }
    end
  end

  attr_reader :norestart
  attr_accessor :lit
end

