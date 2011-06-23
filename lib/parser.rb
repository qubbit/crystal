require(File.expand_path("../../lib/ast",  __FILE__))
require(File.expand_path("../../lib/lexer",  __FILE__))

class Parser < Lexer
  def self.parse(str)
    new(str).parse
  end

  def initialize(str)
    super
    next_token_skip_statement_end
  end

  def parse
    parse_expressions
  end

  def parse_expressions
    exps = []
    while @token.type != :EOF
      exps << parse_expression
      skip_statement_end
    end
    exps
  end

  def parse_expression
    case @token.type
    when :IDENT
      case @token.value
      when :def
        return parse_def
      else
        return parse_call
      end
    else
      return parse_add_or_sub
    end
  end

  def parse_def
    next_token_skip_space_or_newline
    check :IDENT

    name = @token.value
    args = []

    next_token_skip_space

    if @token.type == :'('
      next_token_skip_space_or_newline
      while @token.type != :')'
        check_ident
        args << Arg.new(@token.value)
        next_token_skip_space_or_newline
        if @token.type == :','
          next_token_skip_space_or_newline
        end
      end
      next_token_skip_statement_end
    elsif @token.type == :IDENT
      while @token.type != :NEWLINE && @token.type != :";"
        check_ident
        args << Arg.new(@token.value)
        next_token_skip_space
        if @token.type == :','
          next_token_skip_space_or_newline
        end
      end
      next_token_skip_statement_end
    else
      skip_statement_end
    end

    if @token.type == :IDENT && @token.value == :end
      body = nil
    else
      body = parse_expression
      skip_statement_end
      check_ident :end
    end

    next_token_skip_statement_end
    Def.new name, args, body
  end

  def parse_call
    node_and_next_token Call.new(@token.value)
  end

  def parse_add_or_sub
    left = parse_mul_or_div
    while true
      case @token.type
      when :SPACE
        next_token
      when :"+"
        next_token_skip_space_or_newline
        right = parse_mul_or_div
        left = Add.new left, right
      when :"-"
        next_token_skip_space_or_newline
        right = parse_mul_or_div
        left = Sub.new left, right
      else
        return left
      end
    end

  end

  def parse_mul_or_div
    left = parse_atomic
    while true
      case @token.type
      when :SPACE
        next_token
      when :"*"
        next_token_skip_space_or_newline
        right = parse_atomic
        left = Mul.new left, right
      when :"/"
        next_token_skip_space_or_newline
        right = parse_atomic
        left = Div.new left, right
      else
        return left
      end
    end
  end

  def parse_atomic
    case @token.type
    when :"+"
      next_token_skip_space_or_newline
      check :INT
      node_and_next_token Int.new(@token.value)
    when :"-"
      next_token_skip_space_or_newline
      check :INT
      node_and_next_token Int.new(-@token.value)
    when :INT
      node_and_next_token Int.new(@token.value)
    else
      raise "Unexpected token: #{@token}"
    end
  end

  def node_and_next_token(node)
    next_token
    node
  end

  private

  def check(*token_types)
    raise "Expecting token #{token_types}" unless token_types.any?{|type| @token.type == type}
  end

  def check_ident(value = nil)
    if value
      raise "Expecting token: #{@token.to_s}" unless @token.type == :IDENT && @token.value == value
    else
      raise "Unexpected token: #{@token.to_s}" unless @token.type == :IDENT && @token.value.is_a?(String)
    end
  end
end
