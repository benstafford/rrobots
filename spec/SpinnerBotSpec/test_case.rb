class TestCase
  attr_reader :values
  def initialize values
    @values = values
  end

  def method_missing(method_sym, *arguments, &block)
    @values[method_sym.to_s]
  end
end