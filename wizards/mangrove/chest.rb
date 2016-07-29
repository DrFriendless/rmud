module AccessibleContainer
  def initialize_ac
    @open = true
    @openable = false
  end

  def after_properties_set_ac
    super
    if @openable
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

  def open
    return !@openable || @open
  end

  def persist_ac(data)
    data[persistence_key][:open] = @open
  end

  def restore_ac(data, by_persistence_key)
    @open = data.dig(persistence_key, :open)
  end
end

class Chest < Thing
  include Container
  include AccessibleContainer

  def initialize
    super
    initialize_contents
    initialize_ac
  end

  def persist(data)
    super
    persist_contents(data)
    persist_ac(data)
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
    restore_ac(data, by_persistence_key)
  end

  def after_properties_set
    super
    after_properties_set_ac
  end

  def weight
    # todo
    super
  end
end