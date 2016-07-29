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