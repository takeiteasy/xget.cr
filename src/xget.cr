require "option_parser"
require "ircbot"

module Xget
  VERSION = "0.1.0"

  class User
    getter nick : String,
           user : String,
           pass : String,
           real : String
    
    def initialize(@nick,
                   @user,
                   @pass,
                   @real)
    end
  end

  class Request
    getter channel : String,
           server  : String,
           port    : Int32,
           bot     : String,
           pack    : Int32

    def initialize(@channel,
                   @server,
                   @port,
                   @bot,
                   @pack)
    end

    def to_s
      "[ #{self.channel.empty? ? "nil" : self.channel}, #{self.bot}, #{self.pack} ]"
    end

    def to_a
      ["host=#{server}", "port=#{port}", "channel=#{channel}"]
    end
  end

  class Bot < IRC::Bot
    def on_error(msg)
      # ...
    end
    
    def on_notice(msg)
      # ...
    end
    
    def on_privmsg(msg)
      # ...
    end
  end
end

verbose : Bool = false

def die(msg, status = 1)
  STDERR.puts "ERROR: #{msg}"
  exit status
end

requests = [] of Xget::Request
OptionParser.parse do |p|
  p.banner = "Usage: #{PROGRAM_NAME} [addresses] [arguments]"

  p.on "-v", "--verbose", "Enable verbose output" do
    verbose = true
  end
  
  p.on "-h", "--help", "Show help" do
    puts p
    exit
  end

  p.invalid_option do |arg|
    die "Invalid flag \"#{arg}\"\n\n" + p.to_s
  end

  p.unknown_args do |args|
    args.each do |arg|
      if arg =~ /^(?<chan>\#\S+@)?(?<addr>(irc|ssl|open).\w+.\w{2,3})(?<port>:\d{2,4})?\/(?<bot>\S+)\/(?<packs>[\.&\|\d]+)$/i
        m = $~.named_captures
        chan : String = m["chan"].to_s.chomp '@'
        addr : String = m["addr"].to_s
        port : Int32  = m["port"].nil? ? 6667 : m["port"].to_s.lchop(':').to_i
        bot  : String = m["bot"].to_s
        m["packs"].to_s.split("&").each do |pack|
          case pack
          when /(\d+)\.\.(\d+)(\|\d+)?/
            step_m = $~.captures[2]
            step : Int32 = step_m.nil? ? 1 : step_m.to_s.lchop('|').to_i
            a : Int32 = $1.to_i
            b : Int32 = $2.to_i
            if a >= b || step >= b - a
              die "Invalid pack range \"#{pack}\""
            end
            (a..b).step(step).each do |x|
              requests << Xget::Request.new chan, addr, port, bot, x
            end
          when /\d+/
            requests << Xget::Request.new chan, addr, port, bot, pack.to_i
          else
            die "Invalid pack format \"#{pack}\""
          end
        end
      else
        die "Invalid IRC address \"#{arg}\""
      end
    end
  end
end

#die "Nothing to do! Exiting..." if requests.empty?

split_req = {} of String => Array(Xget::Request)
requests.each do |r|
  split_req[r.server] = Array(Xget::Request).new if !split_req.has_key? r.server
  split_req[r.server] << r
end

split_req.each do |k,v|
  puts "#{k}:"
  v.each do |r|
    puts "\t#{r.to_s}"
  end
end

test = Xget::Bot.new IRC::Options.new(["host=irc.rizon.net", "verbose=true"])
sleep 5.seconds
test.quit
