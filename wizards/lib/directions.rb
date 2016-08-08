module Directions
  def add_direction_verbs()
    direction(:west, :w)
    direction(:east, :e)
    direction(:north, :n)
    direction(:south, :s)
    direction(:out, :exit)
    direction(:in, :enter)
    direction(:up, :u)
    direction(:down, :d)
    direction(:southwest, :sw)
    direction(:southeast, :se)
    direction(:northeast, :ne)
    direction(:northwest, :nw)
  end

  def direction(key, alt=nil)
    v = instance_variable_get("@#{key}")
    if alt && !v
      v = instance_variable_get("@#{alt}")
    end
    v = local_dest(v)
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