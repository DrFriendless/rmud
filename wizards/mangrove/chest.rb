module Openable
  def initialize_openable
    @open = true
  end

  def after_properties_set_openable
    super
    verb(["open", :it]) { |response, command, match|
      if open
        response.message = "The #{short} is already open."
      else
        @open = true
        command.body.location.publish_to_room(OpenEffect.new(command.body, self))
      end
      response.handled = true
    }
    verb(["close", :it]) { |response, command, match|
      if open
        @open = false
        command.body.location.publish_to_room(CloseEffect.new(command.body, self))
      else
        response.message = "The #{short} is not open."
      end
      response.handled = true
    }
  end

  def open
    return !@openable || @open
  end

  def persist_openable(data)
    data[persistence_key][:open] = @open
  end

  def restore_openable(data, by_persistence_key)
    @open = data.dig(persistence_key, :open)
  end
end

module AccessibleContainer
  def after_properties_set_ac
    super
    verb(["look", "inside", :it]) { |response, command, match|
      # todo
      response.handled = true
    }
    alias_verb(["look", "in", :it], ["look", "inside", :it])
    verb(["get", :plus, "from", :it]) { |response, command, match|
      # todo
      response.handled = true
    }
    verb(["put", :plus, "into", :it]) { |response, command, match|
      # todo
      response.handled = true
    }
    alias_verb(["put", :plus, "in", :it], ["put", :plus, "into", :it])
  end
end

class Chest < Thing
  include Container
  include Openable
  include AccessibleContainer

  def initialize
    super
    initialize_contents
    initialize_openable
  end

  def persist(data)
    super
    persist_contents(data)
    persist_openable(data)
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
    restore_openable(data, by_persistence_key)
  end

  def after_properties_set
    super
    after_properties_set_openable
    after_properties_set_ac
  end

  def weight
    # todo
    super
  end

  def examine
    s = super
    if open
      cs = contents.map { |c| c.short }.select { |c| c }.map { |c| "    #{c}"}
      if cs.size > 0
        s += " The #{short} contains:\n" + cs.join("\n")
      else
        s += " The #{short} is open but has nothing in it."
      end
    else
      s += " The #{short} is closed."
    end
  end
end