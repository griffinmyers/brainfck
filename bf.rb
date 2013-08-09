require 'pry'

class UnblancedBracketError < StandardError; end
class InvalidCommandError < StandardError; end

class BrainFck

  def initialize input_string
    @program = input_string.gsub(/[\n\r\t ]/, '')
    @program_index = 0
    @tape_index = 0
    @tape = []
    @loop_stack = []
    @function_mapping = {
      '>' => Proc.new { increment_pointer },
      '<' => Proc.new { decrement_pointer },
      '+' => Proc.new { increment },
      '-' => Proc.new { decrement },
      '.' => Proc.new { write },
      ',' => Proc.new { read },
      '[' => Proc.new { jump },
      ']' => Proc.new { retreat },
    }
    @function_mapping.default = Proc.new { raise invalid_character }
  end

  def run
    while @program_index < @program.length
      @function_mapping[@program[@program_index]].call
      @program_index += 1
    end
  end

  private

  def increment_pointer
    @tape_index += 1
  end

  def decrement_pointer
    @tape_index -= 1
  end

  def increment
    @tape[@tape_index] = (@tape[@tape_index] || Byte.new(0)) + 1
  end

  def decrement
    @tape[@tape_index] = (@tape[@tape_index] || Byte.new(0)) - 1
  end

  def write
    puts @tape[@tape_index].chr
  end

  def read
    print "> "
    @tape[@tape_index] = Byte.new(STDIN.getc.ord)
  end

  def jump
    if is_false?
      @program_index = next_brace
    else
      @loop_stack.push(@program_index)
    end
  end

  def retreat
    if is_false?
      @loop_stack.pop
    else
      raise unbalanced_bracket if @loop_stack.empty?
      @program_index = @loop_stack.last
    end
  end

  def next_brace
    count = 0
    index = 0
    @program[(@program_index + 1)..-1].each_char do |cha|
      index += 1
      if cha == '['
        count += 1
      elsif cha == ']' && count == 0
        return @program_index + index
      elsif cha == ']'
        count -= 1
      end
    end
  end

  def is_false?
    @tape[@tape_index] == 0 || @tape[@tape_index] == nil
  end

  def invalid_character
    InvalidCommandError.new("Invalid Command #{@program[@program_index]} at #{@program_index}")
  end

  def unbalanced_bracket
    UnblancedBracketError.new("Unmatched ] bracket at column #{@program_index}")
  end
end

class Byte

  def initialize value
    @value = value
  end

  def + value
    @value = (@value + value) % 256
    self
  end

  def - value
    @value = (@value - value) % 256
    self
  end

  def == value
    @value == value
  end

  def method_missing sym, *arguments
    @value.send(sym, *arguments)
  end

end

BrainFck.new(ARGF.read).run