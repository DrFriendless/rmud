module Openable
  def initialize_openable
    @open = true
  end

  def after_properties_set_openable
    verb(["open", :it]) { |response, command, match|
      if open
        response.message = "The #{short} is already open."
      else
        @open = true
        command.room.publish_to_room(OpenEffect.new(command.body, self))
      end
      response.handled = true
    }
    verb(["close", :it]) { |response, command, match|
      if open
        @open = false
        command.room.publish_to_room(CloseEffect.new(command.body, self))
      else
        response.message = "The #{short} is not open."
      end
      response.handled = true
    }
  end

  def open
    return @open
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
    verb(["get", :plus, "from", :it]) { |response, command, match|
      itemname = match[0].join(' ')
      item = self.find(itemname)
      if not open
        response.message = "The #{short} is closed."
      elsif item
        item.move_to(command.body)
        command.room.publish_to_room(GetFromEffect.new(command.body, item, self))
      else
        response.message = "There is no such thing in the #{short}."
      end
      response.handled = true
    }
    verb(["put", :plus, "into", :it]) { |response, command, match|
      itemname = match[0].join(' ')
      item = command.body.find(itemname)
      if not open
        response.message = "The #{short} is closed."
      elsif item
        if command.body.wearing?(item)
          response.message = "You'll need to take it off first."
        else
          item.move_to(self)
          command.room.publish_to_room(PutIntoEffect.new(command.body, item, self))
        end
      else
        response.message = "You don't have any such thing."
      end
      response.handled = true
    }
    alias_verb(["put", :plus, "in", :it], ["put", :plus, "into", :it])
  end
end

class OpenableContainer < Thing
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
    s
  end
end

class OpenContainer < Thing
  include Container
  include AccessibleContainer

  def initialize
    super
    initialize_contents
  end

  def persist(data)
    super
    persist_contents(data)
  end

  def restore(data, by_persistence_key)
    super
    restore_contents(data, by_persistence_key)
  end

  def after_properties_set
    super
    after_properties_set_ac
  end

  def weight
    # todo
    super
  end

  def open
    true
  end

  def examine
    s = super
    cs = contents.map { |c| c.short }.select { |c| c }.map { |c| "    #{c}"}
    if cs.size > 0
      s += " The #{short} contains:\n" + cs.join("\n")
    else
      s += " The #{short} but has nothing in it."
    end
    s
  end
end
