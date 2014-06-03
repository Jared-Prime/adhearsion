# encoding: utf-8

require 'pathname'
require 'rbconfig'

module Adhearsion
  module ScriptAhnLoader
    RUBY = File.join(*RbConfig::CONFIG.values_at("bindir", "ruby_install_name")) + RbConfig::CONFIG["EXEEXT"]
    SCRIPT_AHN = File.join('script', 'ahn')

    def self.exec_script_ahn!(args = ARGV, options={})
      cwd = Dir.pwd
      return unless in_ahn_application? || in_ahn_application_subdirectory?

      if in_ahn_application?
        if jruby? && options[:java_opts]
          jruby_exec! args, options[:java_opts]
        else
          exec RUBY, SCRIPT_AHN, *args
        end
      end

      Dir.chdir("..") do
        # Recurse in a chdir block: if the search fails we want to be sure
        # the application is generated in the original working directory.
        exec_script_ahn! unless cwd == Dir.pwd
      end
    rescue SystemCallError
      # could not chdir, no problem just return
    end

    def self.jruby_exec!(args, java_opts)
      exec RUBY, java_opts, '-S', SCRIPT_AHN, *args
    end

    def self.in_ahn_application?(path = '.')
      Dir.chdir(path) { File.exists? SCRIPT_AHN }
    end

    def self.in_ahn_application_subdirectory?(path = Pathname.new(Dir.pwd))
      File.exists?(File.join(path, SCRIPT_AHN)) || !path.root? && in_ahn_application_subdirectory?(path.parent)
    end
  end
end
