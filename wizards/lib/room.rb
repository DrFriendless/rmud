require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'

class Room < Thing
  include Container
  include Singleton
  include Directions

  def initialize()
    super
    initialize_contents
    @lit = false
  end

  def after_properties_set()
    add_direction_verbs()
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

  def on_world_create()
    cs = @thingClass.properties["contains"]
    if cs then
      refs = cs.split()
      refs.map { |rs|
        thing = create(rs)
        if thing; thing.move_to(self) end
      }
    end
  end

  def carriable?()
    false
  end

  def lit?()
    @lit == true || @lit == "true"
  end
end

