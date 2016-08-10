require_relative '../../src/server/thing'

module HasGold
  def initialize_gold
    @gp = 0
  end

  def add_gold(n)
    @gp += (n || 0)
  end

  def pay(n)
    if @gp >= n
      @gp -= n
      return true
    end
    return false
  end

  def persist_gold(data)
    data[persistence_key][:gp] = @gp
  end

  def restore_gold(data, by_persistence_key)
    @gp = data[:gp] || 0
  end

  attr_reader :gp
end

class Gold < Thing
  include HasGold

  def initialize
    super
    initialize_gold
  end

  def short
    "#{@gp} gold pieces"
  end

  def is_called?(s)
    s == "gold" || s == "money" || s == "#{@gp}gp" || s == "#{@gp} gp" || s == "#{@gp} gold" || s == "#{@gp} gold pieces" ||
        (@gp == 1 && s == "1 gold piece")
  end

  def carriable?
    true
  end

  def after_properties_set
    super
    verb(["get", :it]) { |response,command,match|
      if @location == command.body.location
        move_to(command.body)
        command.body.location.publish_to_room(TakeEffect.new(command.body, self))
        response.handled = true
      end
    }
    alias_verb(["take", :it], ["get", :it])
  end

  def move_to(loc)
    other = loc.find("gold")
    super
    if location.is_a? HasGold
      location.add_gold(@gp)
      destroy
    elsif other
      other.add_gold(@gp)
      destroy
    end
  end

  def weight
    0
  end

  def persist(data)
    super
    persist_gold(data)
  end

  def restore(data, by_persistence_key)
    restore_gold(data, by_persistence_key)
  end
end

GOLD_PATTERN_1 = /^(\d+) ?gp$/
GOLD_PATTERN_2 = /^(\d+) gold( pieces)?$/
GOLD_PATTERN_3 = /^1 gold piece$/
PATTERNS = [ GOLD_PATTERN_1, GOLD_PATTERN_2, GOLD_PATTERN_3 ]

def parse_money(s)
  if GOLD_PATTERN_3 =~ s
    return 1
  end
  [ GOLD_PATTERN_1, GOLD_PATTERN_2 ].each { |p|
    p "pattern #{p} s #{s}"
    match = p.match(s)
    if match
      p "MATCH #{match} #{match[0]}"
      return match[0].to_i
    end
  }
end

def is_money?(s)
  PATTERNS.any? { |p| p =~ s }
end