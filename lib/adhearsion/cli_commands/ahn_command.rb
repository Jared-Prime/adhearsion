# encoding: utf-8

module Adhearsion
  module CLI
    class AhnCommand < Thor
      map %w(-h --h -help --help) => :help
      map %w(-v --v -version --version) => :version
      map %w(-) => :start

      register ::Adhearsion::CLI::PluginCommand, 'plugin', 'plugin <command>', 'Plugin Tasks.'

      check_unknown_options!

      def self.exit_on_failure?
        true
      end

      desc "create /path/to/directory", "Create a new Adhearsion application under the given path"
      def create(path)
        require 'adhearsion/generators/app/app_generator'
        Generators::AppGenerator.start
      end

      desc "generate [generator_name] arguments", Generators.help
      def generate(generator_name = nil, *args)
        if generator_name
          Generators.invoke generator_name
        else
          help 'generate'
        end
      end

      desc "version", "Shows Adhearsion version"
      def version
        say "Adhearsion v#{Adhearsion::VERSION}"
        exit 0
      end

      desc "start </path/to/directory>", "Start the Adhearsion server in the foreground with a console"
      method_option :noconsole, type: :boolean, aliases: %w{--no-console}
      method_option :java_opts, type: :string, aliases: %w{--java-opts}
      def start(path = nil)
        start_app path, options
      end

      desc "daemon </path/to/directory>", "Start the Adhearsion server in the background"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def daemon(path = nil)
        start_app path, :daemon, options[:pidfile]
      end

      desc "stop </path/to/directory>", "Stop a running Adhearsion server"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def stop(path = nil)
        execute_from_app_dir! path

        pid_file = if options[:pidfile]
          File.exists?(File.expand_path(options[:pidfile])) ?
            options[:pidfile] :
            File.join(path, options[:pidfile])
        else
          path = Dir.pwd
          File.join path, Adhearsion::Initializer::DEFAULT_PID_FILE_NAME
        end
        pid_file = File.expand_path pid_file

        begin
          pid = File.read(pid_file).to_i
        rescue
          raise PIDReadError, pid_file
        end

        raise PIDReadError, pid_file if pid.nil?

        say "Stopping Adhearsion server at #{path} with pid #{pid}"
        waiting_timeout = Time.now + 15
        begin
          ::Process.kill "TERM", pid
          sleep 0.25 while process_exists?(pid) && Time.now < waiting_timeout
          ::Process.kill "KILL", pid
        rescue Errno::ESRCH
        end

        File.delete pid_file if File.exists? pid_file
      end

      desc "restart </path/to/directory>", "Restart the Adhearsion server"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def restart(path = nil)
        execute_from_app_dir! path
        begin
          invoke :stop
        rescue PIDReadError => e
          puts e.message
        end
        invoke :daemon
      end

      protected

      def start_app(path, options, pid_file = nil)
        mode = options[:noconsole] ? :simple : :console
        say "Starting Adhearsion server at #{Dir.pwd}"
        Adhearsion::Initializer.start :mode => mode, :pid_file => pid_file
      end

      def running_script_ahn?
        $0.to_s == "script/ahn"
      end

      def in_app?
        ScriptAhnLoader.in_ahn_application? or ScriptAhnLoader.in_ahn_application_subdirectory?
      end

      def process_exists?(pid = nil)
        # FIXME: Raise some error here
        return false if pid.nil?
        `ps -p #{pid} | sed -e '1d'`.strip.empty?
      end

      def method_missing(action, *args)
        help
        raise UnknownCommand, [action, *args] * " "
      end
    end
  end
end
