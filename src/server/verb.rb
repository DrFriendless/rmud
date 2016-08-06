class Verb
  def initialize(pattern, block)
    @pattern = pattern
    @block = block
  end

  attr_reader :pattern
  attr_reader :block

  def handle(response, command, match)
    @block.call(response, command, match)
  end

  def match(command, verb_owner)
    matches = []
    result = match_words(@pattern, command.words, verb_owner, matches, command.body)
    if result
      matches
    else
      false
    end
  end

  def match_words(pattern, words, verb_owner, matches, verb_invoker)
    if pattern.empty? && words.empty?; return true end
    if pattern.size == 1 && (pattern[0] == :star || pattern[0] == "*") && words.empty?
      return true
    end
    if pattern.empty? || words.empty?; return false end
    if pattern[0] == :star
      (0..words.size).each { |n|
        matches.push(words.take(n))
        if match_words(pattern.drop(1), words.drop(n), verb_owner, matches, verb_invoker)
          return true
        else
          matches.pop
        end
      }
      false
    elsif pattern[0] == :plus
      (1..words.size).each { |n|
        matches.push(words.take(n))
        if match_words(pattern.drop(1), words.drop(n), verb_owner, matches, verb_invoker)
          return true
        else
          matches.pop
        end
      }
      false
    elsif pattern[0] == :someone
      (1..words.size).each { |n|
        target = verb_invoker.location.find(words[0,n].join(' '))
        target = nil unless target.is_a? Body
        matches.push(words.take(n))
        if target && match_words(pattern.drop(1), words.drop(n), verb_owner, matches, verb_invoker)
          return true
        else
          matches.pop
        end
      }
      false
    elsif pattern[0] == :it
      (1..words.size).each { |n|
        matches.push(words.take(n))
        if verb_owner.is_called?(words[0,n].join(" ")) && match_words(pattern.drop(1), words.drop(n), verb_owner, matches, verb_invoker)
          return true
        else
          matches.pop
        end
      }
      return false
    else
      (pattern[0].downcase == words[0].downcase) && match_words(pattern.drop(1), words.drop(1), verb_owner, matches, verb_invoker)
    end
  end
end
