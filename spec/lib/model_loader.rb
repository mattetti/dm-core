# ---
# Overview
# ========
# ModelLoader is a method for loading methods models for specs in a way
# that will ensure that each spec will be an a pristine state when run.
#
# The problem is that if a spec needs to modify a model, the modifications
# should not carry over to the next spec. As such, all models are
# destroyed at the end of the spec and reloaded at the start.
#
# The second problem is that DataMapper::Resource keeps track
# of every class that it is included in. This is used for automigration.
# A number of specs run automigrate, and we don't want all the classes
# that were defined in other specs to be migrated as well.
#
# Usage
# =====
#
# Sets the specified model metaphors to be loaded before each spec and
# destroyed after each spec in the current example group. This method
# can be used in a describe block or in a before block.
#
# ==== Parameters
# *metaphor<Symbol>:: The name of the metaphor to load (this is just the filename of
#               file in specs/models)
#
# ==== Example
#
# describe "DataMapper::Associations" do
#
#   load_models_for_metaphor :zoo, :blog
#
#   it "should be awesome" do
#     Zoo.new.should be_awesome
#   end
# end
module ModelLoader

  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval { include InstanceMethods }
    # base.before(:all) { load_models(:global) }
    base.after(:all) { unload_models }
  end

  module ClassMethods

    def load_models_for_metaphor(*metaphors)
      before(:all) { load_models_for_metaphor(*metaphors) }
    end

  end

  module InstanceMethods

    def load_models_for_metaphor(*metaphors)
      files = metaphors.map { |m| DataMapper.root / "spec" / "models" / "#{m}.rb" }

      klasses = object_space_classes.dup
      files.each { |file| load file }
      loaded_models.concat(object_space_classes - klasses)
    end

    def unload_models
      while model = loaded_models.pop
        remove_model(model)
      end
    end

    def loaded_models
      @loaded_models ||= []
    end

  private

    def object_space_classes
      klasses = []
      ObjectSpace.each_object(Class) {|o| klasses << o}
      klasses
    end

    def remove_model(klass)
      DataMapper::Resource.descendants.delete(klass)

      list = klass.to_s.split('::')
      list.shift if list.first.blank?
      last = list.pop
      obj  = obj = list.empty? ? Object : Object.full_const_get(list.join('::'))

      obj.module_eval { remove_const last }
    end
  end
end

Spec::Runner.configure do |config|
  config.include(ModelLoader)
end
