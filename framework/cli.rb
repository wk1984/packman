module PACKMAN
  class CLI
    def self.delegated_methods
      [:green, :blue, :red, :yellow, :bold, :caveat, :pause,
       :report_notice, :report_error, :report_warning,
       :blue_arrow, :under_construction!, :ask, :get_answer]
    end

    @@color_map = {
      :red    => 31,
      :green  => 32,
      :yellow => 33,
      :blue   => 34,
      :purple => 35,
      :cyan   => 36,
      :gray   => 37,
      :white  => 39,
    }

    def self.reset
      escape 0
    end

    def self.width
      if not PACKMAN.does_command_exist? 'tput'
        80
      else
        `tput cols`.strip.to_i
      end
    end

    def self.truncate str
      str.to_s[0, width - 4]
    end

    def self.bold str
      "#{escape(1)}#{str}#{escape(0)}"
    end

    def self.color n
      escape "0;#{n}"
    end

    def self.underline n
      escape "4;#{n}"
    end

    def self.escape n
      "\033[#{n}m" if $stdout.tty?
    end

    @@color_map.each do |color_name, color_code|
      self.class_eval(<<-EOT)
        def self.#{color_name} str = nil
          if str
            "\#{#{color_name}}\#{str}\#{reset}"
          else
            color #{color_code}
          end
        end
      EOT
    end

    def self.blue_arrow message, options = []
      options = [options] if not options.class == Array
      print "#{blue '==>'} "
      if options.include? :truncate
        print "#{truncate message}\n"
      else
        print "#{message}\n"
      end
    end

    def self.print_call_stack
      Kernel.caller.each do |stack_line|
        print "#{red '==>'} #{stack_line}\n"
      end
    end

    def self.report_notice message
      print "[#{green 'Notice'}]: #{message}\n"
    end

    def self.report_warning message
      print "[#{yellow 'Warning'}]: #{message}\n"
      print_call_stack if CommandLine.has_option? '-debug'
    end

    def self.report_error message, options = nil
      options = [options] if not options or options.class != Array
      print "[#{red 'Error'}]: #{message}\n"
      print_call_stack if CommandLine.has_option? '-debug'
      if not options.include? :keep_pid_file
        pid_file = "#{ENV['PACKMAN_ROOT']}/.pid"
        PACKMAN.rm pid_file if File.exist? pid_file and CommandLine.process_exclusive?
      end
      exit
    end

    def self.repeat x, times, color, suffix = nil
      for i in 1..times
        if color
          print "#{eval "#{color} x"}"
        else
          print x
        end
      end
      print suffix
    end

    def self.caveat message
      times = [80, width].min
      repeat '#', times/2-4, 'red', "#{red ' CAVEAT '}"
      repeat '#', times-(times/2-4)-8, 'red', "\n"
      message.each_line do |line|
        print line
      end
      repeat '#', times, 'red', "\n"
    end

    def self.under_construction!
      print ":( PACKMAN is under construction for this function! Thank you for your support!\n"
      print_call_stack if CommandLine.has_option? '-debug'
      exit
    end

    def self.ask question, possible_answers
      question.split("\n").each do |line|
        print "#{yellow '==>'} #{line}\n"
      end
      print "#{yellow '==>'} Possible answers:\n"
      for i in 0..possible_answers.size-1
        print "    #{bold i}: #{possible_answers[i]}\n"
      end
    end

    def self.get_answer possible_answers, options = nil
      options = [options] if not options or options.class != Array
      while true
        print '> '
        if possible_answers
          begin
            inputs = STDIN.gets.strip.split(/\s/)
            report_error "You need to input something!" if inputs.empty?
            for i in 0..inputs.size-1
              inputs[i] = Integer(inputs[i])
              if not (0..possible_answers.size-1).cover? inputs[i]
                report_error "Input in out of range!"
              end
            end
          rescue
            report_error "Input should be integers!"
          end
          if options.include? :only_one
            if inputs.size != 1
              report_error 'Only one should be selected!'
            end
            inputs = inputs.first
          end
        else
          inputs = STDIN.gets
        end
        return inputs
      end
    end

    def self.pause options = {}
      print options[:message]
      if options.has_key? :seconds
        sleep options[:seconds]
      else
        STDIN.gets
      end
      p
    end
  end
end
