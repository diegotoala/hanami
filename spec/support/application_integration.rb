# frozen_string_literal: true

require "hanami/devtools/integration/files"
require "hanami/devtools/integration/with_tmp_directory"

module TestNamespace
  def remove_constants
    constants.each do |name|
      remove_const(name)
    end
  end
end

RSpec.shared_context "Application integration" do
  let(:application_modules) { %i[TestApp Admin Main Search] }
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, :application_integration
  config.include RSpec::Support::WithTmpDirectory, :application_integration
  config.include_context "Application integration", :application_integration

  config.before :each, :application_integration do
    @load_paths = $LOAD_PATH.dup

    application_modules.each do |app_module|
      Object.const_set(app_module, Module.new { |m| m.extend(TestNamespace) })
    end
  end

  config.after :each, :application_integration do
    $LOAD_PATH.replace(@load_paths)
    $LOADED_FEATURES.delete_if do |feature_path|
      feature_path =~ %r{hanami/(setup|init|boot|application/container/boot)}
    end

    application_modules.each do |app_module|
      Object.const_get(app_module).remove_constants
      Object.send :remove_const, app_module
    end

    %i[@_application @_app].each do |ivar|
      Hanami.remove_instance_variable(ivar) if Hanami.instance_variable_defined?(ivar)
    end
  end
end
