module Directions
  def add_direction_verbs()
    direction(:west, :w)
    direction(:east, :e)
    direction(:north, :n)
    direction(:south, :s)
    direction(:exit, :out)
    direction(:enter, :in)
    direction(:up, :u)
    direction(:down, :d)
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
end