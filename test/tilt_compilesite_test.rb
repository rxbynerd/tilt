require 'contest'
require 'tilt'

class CompileSiteTest < Test::Unit::TestCase
  def setup
    GC.start
  end

  class CompilingTemplate < Tilt::Template
    def prepare
    end

    def template_source
      @data.inspect
    end
  end

  class Scope
    include Tilt::CompileSite
  end

  test "compiling template source to a method" do
    template = CompilingTemplate.new { |t| "Hello World!" }
    template.render(Scope.new)
    method_name = template.send(:compiled_method_name, [])
    method_name = method_name.to_sym if Symbol === Kernel.methods.first
    assert Tilt::CompileSite.instance_methods.include?(method_name),
      "CompileSite.instance_methods.include?(#{method_name.inspect})"
    assert Scope.new.respond_to?(method_name),
      "scope.respond_to?(#{method_name.inspect})"
  end

  test 'garbage collecting compiled methods' do
    template = CompilingTemplate.new { '' }
    method_name = template.send(:compiled_method_name, [])
    template.render(Scope.new)
    assert Scope.new.respond_to?(method_name)
    Tilt::Template.send(
      :garbage_collect_compiled_template_method,
      Tilt::CompileSite,
      method_name
    )
    assert !Scope.new.respond_to?(method_name), "compiled method not removed"
  end

  def self.create_and_destroy_template
    template = CompilingTemplate.new { 'Hello World' }
    template.render(Scope.new)
    method_name = template.send(:compiled_method_name, [])
    method_name = method_name.to_sym if Symbol === Kernel.methods.first
    [template.object_id, method_name]
  end

  finalized_object_id, finalized_method_name = create_and_destroy_template

  test "triggering compiled method gc finalizer" do
    assert !Tilt::CompileSite.instance_methods.include?(finalized_method_name),
      "CompileSite.instance_methods.include?(#{finalized_method_name.inspect})"
    assert !Scope.new.respond_to?(finalized_method_name),
      "Scope.new.respond_to?(#{finalized_method_name.inspect})"
  end
end
