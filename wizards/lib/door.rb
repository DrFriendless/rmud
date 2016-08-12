require_relative '../../src/server/thing'
require_relative './chest'
require_relative './directions'

class Door < Thing
  include Openable
  include Directions

  def initialize
    super
    initialize_openable
    @name = 'door'
    @identity = @name
  end

  def after_properties_set
    super
    after_properties_set_openable
    add_direction_verbs
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
        elsif open
          command.body.go_to(v, "#{key}")
        else
          command.body.tell("You can't go that way because the #{name} is closed.")
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

  def persist(data)
    super
    data[persistence_key][:open] = @open
  end

  def restore(data, by_persistence_key)
    @open = data[:open]
  end

  attr_reader :name
end