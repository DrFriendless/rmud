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

  def match(command, subject)
    matches = []
    result = match_words(@pattern, command.words, subject, matches)
    if result
      matches
    else
      false
    end
  end

  def match_words(pattern, words, subject, matches)
    if pattern.empty? && words.empty?; return true end
    if pattern.size == 1 && (pattern[0] == :star || pattern[0] == "*") && words.empty?
      return true
    end
    if pattern.empty? || words.empty?; return false end
    if pattern[0] == :star
      (0..words.size).each { |n|
        matches.push(words.take(n))
        if match_words(pattern.drop(1), words.drop(n), subject, matches)
          return true
        else
          matches.pop
        end
      }
      false
    elsif pattern[0] == :plus
      (1..words.size).each { |n|
        matches.push(words.take(n))
        if match_words(pattern.drop(1), words.drop(n), subject, matches)
          return true
        else
          matches.pop
        end
      }
      false
    elsif pattern[0] == :someone && subject.is_a?(Body)
      p "Is #{subject.short} a someone?"
      (1..words.size).each { |n|
        matches.push(words.take(n))
        p "Is #{subject.short} called #{words[0,n].join(" ")}"
        if subject.is_called?(words[0,n].join(" ")) && match_words(pattern.drop(1), words.drop(n), subject, matches)
          return true
        else
          matches.pop
        end
      }
      false
    elsif pattern[0] == :it
      (1..words.size).each { |n|
        matches.push(words.take(n))
        if subject.is_called?(words[0,n].join(" ")) && match_words(pattern.drop(1), words.drop(n), subject, matches)
          return true
        else
          matches.pop
        end
      }
      return false
    else
      (pattern[0].downcase == words[0].downcase) && match_words(pattern.drop(1), words.drop(1), subject, matches)
    end
  end
end
