require_relative './thing'

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
    data[:gp] = @gp
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
ALL_GOLD = /^all gold$/
ALL_GP = /^all gp$/
PATTERNS = [ GOLD_PATTERN_1, GOLD_PATTERN_2, GOLD_PATTERN_3, ALL_GOLD, ALL_GP ]

def parse_money_quantity(s)
  if s.is_a? Integer
    return s
  end
  if GOLD_PATTERN_3 =~ s
    return 1
  end
  [ GOLD_PATTERN_1, GOLD_PATTERN_2 ].each { |p|
    match = p.match(s)
    if match
      return match[0].to_i
    end
  }
end

def parse_money(s, all)
  if is_all_money?(s)
    all
  else
    parse_money_quantity(s)
  end
end

def is_all_money?(s)
  [ALL_GOLD, ALL_GP].any? { |p| p =~ s }
end

def is_money?(s)
  PATTERNS.any? { |p| p =~ s }
end