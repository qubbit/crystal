module Crystal
  class Scope
    def next
      @scope
    end

    def parent
      @scope
    end

    def method_missing(name, *args)
      @scope.send name, *args
    end
  end

  class DefScope < Scope
    attr_accessor :def

    def initialize(scope, a_def)
      @scope = scope
      @def = a_def
    end

    def add_expression(node)
      if @def.is_a?(TopLevelDef) || node.is_a?(Def) || node.is_a?(Prototype)
        @scope.add_expression node
      else
        @def.local_variables[node.name] = node
      end
    end

    def find_expression(name)
      local = find_local_expression(name)
      return local if local

      self.next.find_expression name
    end

    def find_local_expression(name)
      arg = @def.args.select{|arg| arg.name == name}.first
      return arg if arg

      @def.local_variables[name]
    end

    def next
      tentative = @scope
      tentative = tentative.parent while tentative.is_a? DefScope
      tentative
    end

    def to_s
      "Def<#{@def.name}> -> #{@scope.to_s}"
    end
    alias inspect to_s
  end

  class ClassDefScope < Scope
    def initialize(scope, a_class)
      @scope = scope
      @class = a_class
    end

    def add_expression(node)
      name = node.name
      node.name = "#{@class.name}##{name}"
      node.args.insert 0, Var.new("self")
      node.args_length = node.args.length - 1
      @class.define_method name, node
    end

    def to_s
      "Class<#{@class.name}> -> #{@scope.to_s}"
    end
    alias inspect to_s
  end

  class BlockScope < Scope
    def initialize(scope, context)
      @scope = scope
      @context = context
    end

    def find_expression(name)
      node = @context.find_expression name
      return node if node

      @scope.find_expression name
    end

    def to_s
      "Block<#{@context.scope.def.name}> -> #{@scope.to_s}"
    end
  end

  class BlockContext
    def find_expression(name)
      result = @references[name]
      return result if result

      node = @scope.find_local_expression name
      if node
        node = BlockReference.new self, node
        @references[name] = node
      end
      node
    end
  end
end
