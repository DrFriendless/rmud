# FIXME: items can't claim two spots of the same type, e.g. you can't have an item which is two rings.
module Wearing
  def initialize_wearing
    @wear_slots = {'necklace' => [nil], 'hat' => [nil], 'ring' => [nil, nil], 'amulet' => [nil],
                   'righthand' => [nil], 'lefthand' => [nil], 'shoes' => [nil]}
  end

  # can we put it on now?
  def space_to_wear?(slots)
    slots.all? { |s| @wear_slots[s]&.include?(nil) }
  end

  # can we put it on now?
  def wearing_in_slots(slots)
    result = []
    slots.each { |s|
      if @wear_slots[s]
        @wear_slots[s].each { |x| if x && !result.include?(x); result.push(x) end }
      end
    }
    result
  end

  # do we even have the slots for this
  def could_wear?(slots)
    slots.all? { |s| @wear_slots[s] && @wear_slots[s].size > 0 }
  end

  # put it on
  def wear(item)
    slots = item.slots
    slots.each { |s| i = @wear_slots[s].find_index(nil); @wear_slots[s][i] = item }
  end

  # take it off
  def remove(item)
    slots = item.slots
    slots.each { |s| i = @wear_slots[s].find_index(item); @wear_slots[s][i] = nil }
  end

  def wearing?(obj)
    return false unless obj.slots
    obj.slots.any? { |slot| @wear_slots[slot]&.include?(obj) }
  end

  def persist_wearing(data)
    # TODO
  end

  def wielded_weapon
    @wear_slots.each_value { |items| items.each { |x| if x.is_a?(Weapon) && wearing?(x); return x; end } }
    nil
  end
end

module HitPoints
  attr_accessor :hp
  attr_accessor :maxhp

  def initialize_hp
    @hp = 0
    @maxhp = 0
  end

  def after_properties_set_hp
    if !@maxhp || @maxhp <= 0
      @maxhp = 1
    end
    if !@hp || @hp <= 0
      @hp = @maxhp
    end
  end

  def injured?
    @hp < @maxhp
  end

  def damage(n)
    alive = @hp > 0
    @hp -= n
    # return whether we were just killed
    alive && @hp <= 0
  end

  def heal(n)
    if @hp < @maxhp
      @hp += n
      if @hp > @maxhp; @hp = @maxhp end
      if @hp == @maxhp
        tell("You feel better now.")
      end
    end
  end

  def persist_hit_points(data)
    data[:maxhp] = @maxhp
    data[:hp] = @hp
  end

  def restore_hit_points(data, by_persistence_key)
    @maxhp = data[:maxhp]
    @hp = data[:hp]
  end

  def dead?
    @hp <= 0
  end
end

