# encoding: utf-8

require 'pathname'
require 'rbconfig'

module Adhearsion
  module ScriptAhnLoader
    RUBY = File.join(*RbConfig::CONFIG.values_at("bindir", "ruby_install_name")) + RbConfig::CONFIG["EXEEXT"]
    SCRIPT_AHN = File.join('script', 'ahn')

    def self.exec_script_ahn!(args = ARGV, options={})
      return
    end
  end
end
