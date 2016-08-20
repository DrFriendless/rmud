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
          if !find_by_class(tcr)
            thing = world.instantiate_gold(rs)
            if thing; thing.move_to(self) end
          end
        else
          tcr = ThingClassRef.new(@thingClass.wizard, rs)
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

