require_relative '../../src/server/thing'

module HasGold
  def initialize_gold
    @gp = 0
  end

  def add_gold(n)
    @gp += n
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
end

GOLD_PATTERN_1 = "^(\d+) gold"
GOLD_PATTERN_2 = "^(\d+) gp"
GOLD_PATTERN_3 = "^(\d+) gold pieces"
GOLD_PATTERN_4 = "^(\d+)gp"
GOLD_PATTERN_5 = "^1 gold piece"
PATTERNS = [ GOLD_PATTERN_1, GOLD_PATTERN_2, GOLD_PATTERN_3, GOLD_PATTERN_4, GOLD_PATTERN_5 ]

def parse_money(s)
  if GOLD_PATTERN_5 =~ s
    return 1
  end
  [ GOLD_PATTERN_1, GOLD_PATTERN_2, GOLD_PATTERN_3, GOLD_PATTERN_4 ].each { |p|
    match = p.match(s)
    if match; return match[0].to_i end
  }
end

def is_money?(s)
  PATTERNS.any? { |p| p =~ s }
end