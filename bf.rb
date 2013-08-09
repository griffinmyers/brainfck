class UnblancedBracketError < StandardError; end
class InvalidCommandError < StandardError; end

class BrainFck

  # Brainfuck as a language basically implements a Turing machine. You have
  # a tape (array) and a tape pointer, and all you do is wander around said
  # tape and increment or decrement values on said tape. My tape is made up of
  # bytes initialized to zero. Note that the byte values will overflow and
  # underflow.
  #
  # What's really wild about Brainfuck is that it's Turing complete. I'm still
  # waiting on a web framework written in it.
  #
  # @program:           the program string ingested from ARGF
  # @program_length:    the length of the program in bytes
  # @program_index:     the index of the current instruction being evaluated
  #
  # @tape:              the tape on which bytes are stored, our program's memory
  # @tape_index:        the specific byte on the tape currently pointed at
  #
  # @loop_stack:        a stack that holds the index of opening brackets. this
  #                     makes jumping back to the top of a loop easy

  def initialize input_string
    @program = input_string.gsub(/[\n\r\t ]/, '')
    @program_length = @program.length - 1
    @program_index = -1
    @tape = [Byte.new(0)]
    @tape_index = 0
    @loop_stack = []
  end

  def run
    while @program_index < @program_length
      case @program[@program_index += 1].chr
        when '>' then increment_pointer
        when '<' then decrement_pointer
        when '+' then increment
        when '-' then decrement
        when '.' then write
        when ',' then read
        when '[' then jump
        when ']' then retreat
        else raise invalid_character
      end
    end
    print "\n"
  end

  private

  def increment_pointer
    @tape_index += 1
    @tape[@tape_index] ||= Byte.new(0)
  end

  def decrement_pointer
    @tape_index -= 1
    @tape[@tape_index] ||= Byte.new(0)
  end

  def increment
    @tape[@tape_index] += 1
  end

  def decrement
    @tape[@tape_index] -= 1
  end

  def write
    print @tape[@tape_index].chr
  end

  def read
    print "\n> "
    @tape[@tape_index] = Byte.new(STDIN.getc.ord)
  end

  def jump
    @tape[@tape_index] == 0 ? @program_index = closing_brace : @loop_stack.push(@program_index)
  end

  def retreat
    if @tape[@tape_index] == 0
      @loop_stack.pop
    else
      @program_index = @loop_stack.last
      raise unbalanced_bracket unless @program_index
    end
  end

  def closing_brace
    count = 0
    index = 0
    @program[(@program_index + 1)..-1].each_char do |c|
      index += 1
      if c == '['
        count += 1
      elsif c == ']' && count == 0
        return @program_index + index
      elsif c == ']'
        count -= 1
      end
    end

    raise unbalanced_bracket
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