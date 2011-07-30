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
    def initialize(scope, a_def)
      @scope = scope
      @def = a_def
      @local_variables = {}
    end

    def global?
      @def.is_a? TopLevelDef
    end

    def add_expression(node)
      if @def.is_a?(TopLevelDef) || node.is_a?(Def) || node.is_a?(Prototype)
        @scope.add_expression node
      else
        @local_variables[node.name] = node
      end
    end

    def find_expression(name)
      arg = @def.args.select{|arg| arg.name == name}.first
      return arg if arg

      var = @local_variables[name]
      return var if var

      self.next.find_expression name
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

    def global?
      true
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
end
