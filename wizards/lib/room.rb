require_relative '../../src/server/thingutil.rb'
require_relative '../../src/server/thing.rb'

class Room < Thing
  include Container
  include Singleton

  def initialize()
    super
    initialize_contents
    @lit = false
  end

  def after_properties_set()
    direction(:west, :w)
    direction(:east, :e)
    direction(:north, :n)
    direction(:south, :s)
    direction(:exit, :out)
    direction(:enter, :in)
    direction(:up, :u)
    direction(:down, :d)
  end

  def publish_to_room(effect)
    @contents.each { |c| c.effect(effect) }
  end

  def direction(key, alt=())
    v = instance_variable_get("@#{key}")
    if v && v.count("/") == 1
      v = @thingClass.wizard + "/" + v
      instance_variable_set("@#{key}", v)
    end
    if v
      verb(["#{key}"]) { |response, command, match|
        command.body.go_to(v, "#{key}")
        response.handled = true
        response.direction = true
      }
    else
      # we don't define that direction, but we do know it is a direction so mark it as such.
      verb(["#{key}"]) { |response, command, match|
        response.direction = true
      }
    end
    if alt; alias_verb(["#{alt}"], ["#{key}"]) end
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

