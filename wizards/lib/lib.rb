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
    direction(:out)
    direction(:in)
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
        # todo notify the room
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
        create(rs).move_to(self)
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

# a thing that can't be seen but can define verbs
class Virtual < Thing
  # properties loaded from YAML have been set
  def after_properties_set()
    if @examine_it
      verb(["examine", :it]) { |response, command, match|
        response.message = @examine_it
        response.handled = true
      }
    end
    if @climb_it_no
      verb(["climb", :it]) { |response, command, match|
        response.message = @climb_it_no
        response.handled = true
      }
    end
    if @climb_it_yes
      @climb_it_yes = destination(@climb_it_yes)
      verb(["climb", :it]) { |response, command, match|
        command.body.go_to(@climb_it_yes)
        response.handled = true
      }
    end
    if @enter_it
      @enter_it = destination(@enter_it)
      verb(["enter", :it]) { |response, command, match|
        command.body.go_to(@enter_it)
        response.handled = true
      }
    end
    if @enter
      @enter = destination(@enter)
      verb(["enter", :it]) { |response, command, match|
        command.body.go_to(@enter)
        response.handled = true
      }
    end
  end

  def short
    ()
  end

  def long
    ()
  end
end