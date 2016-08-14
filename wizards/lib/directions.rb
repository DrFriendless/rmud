class GuardedResult
  attr_accessor :blocked
  attr_accessor :message
  attr_accessor :guard
end

module Guarded
  def check_for_guarded(key, location)
    result = GuardedResult.new
    gk = location.instance_variable_get("@#{key}")
    result.blocked = false
    result.message = nil
    if gk
      guard = location.find(gk)
      if guard && (!guard.is_a? Corpse)
        result.guard = guard
        result.blocked = true
        guard_msg_key = "#{key}_message"
        result.message = location.instance_variable_get("@#{guard_msg_key}")
        result.message = "#{guard.short} blocks your way!" unless result.message
      end
    end
    result
  end
end

module Directions
  include Guarded

  def add_direction_verbs()
    direction(:west, :w, "go west")
    direction(:east, :e, "go east")
    direction(:north, :n, "go north")
    direction(:south, :s, "go south")
    direction(:out, :exit, "go out")
    direction(:in, :enter, "go in")
    direction(:up, :u, "go up")
    direction(:down, :d, "go down")
    direction(:southwest, :sw, "go southwest")
    direction(:southeast, :se, "go southeast")
    direction(:northeast, :ne, "go northeast")
    direction(:northwest, :nw, "go northwest")
  end

  def direction(key, alt, words)
    v = instance_variable_get("@#{key}")
    if alt && !v
      v = instance_variable_get("@#{alt}")
    end
    v = local_dest(v)
    if v
      verb(["#{key}"]) { |response, command, match|
        guard_key = "guard_#{key}"
        gr = check_for_guarded(guard_key, command.room)
        if gr.blocked
          command.body.tell(gr.message)
        else
          command.body.go_to(v, "#{key}")
        end
        response.direction = true
        response.handled = true
      }
    else
      # we don't define that direction, but we do know it is a direction so mark it as such.
      verb(["#{key}"]) { |response, command, match|
        response.direction = true
      }
    end
    add_aliases(key, alt, words)
  end

  def add_aliases(key, alt, words)
    alias_verb(["#{alt}"], ["#{key}"])
    alias_verb(words.split, ["#{key}"])
  end
end