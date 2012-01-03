$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'battlefield'
require 'bullet'
require 'explosion'
require 'robot'
require 'numeric'

##############################################
# arena
##############################################

def usage
  puts "usage: teamExperimenter.rb [resolution] [-timeout=<N>] [-teams=<N>] <FirstRobotClassName[.rb]> <SecondRobotClassName[.rb]> <...>"
  puts "\t[resolution] (optional) should be of the form 640x480 or 800*600. default is 800x800"
  puts "\t[match] (optional) to replay a match, put the match# here, including the #sign.  "
  puts "\t[-timeout=<N>] (optional, default 50000) number of ticks a match will last at most."
  puts "\t[-teams=<N>] (optional) split robots into N teams. Match ends when only one team has robots left."
  puts "\tthe names of the rb files have to match the class names of the robots"
  puts "\t(up to 8 robots)"
  puts "\te.g. 'ruby teamExperimenter.rb SittingDuck NervousDuck'"
  puts "\t or 'ruby teamExperimenter.rb 600x600 #1234567890 SittingDuck NervousDuck'"
  exit
end

def run(battlefield, trial)
  until battlefield.game_over
    battlefield.tick
  end
  record_outcome(battlefield)
end

@win_record = []
def record_outcome(battlefield)
  teams = battlefield.teams.find_all{|name,team| !team.all?{|robot| robot.dead} }
  teams.map do |name,team|
        @win_record<<name
    print "#{team} won\n"
  end
end

def print_aggregate_results number_of_rounds
  win_counts = []
  @win_record.each do |team_number|
    if (win_counts[team_number].nil?)
      win_counts[team_number] = 0
    end
    win_counts[team_number] += 1
  end
  c = 0

  win_counts.each do |count|
    count = 0 if count.nil?
    $stderr.print "Team #{c}: #{100*count/number_of_rounds}%   "
    c = c + 1
  end
  puts

end

$stdout.sync = true

number_of_rounds = 100
ARGV.grep( /^-rounds=(\d+)/ )do |item|
  number_of_rounds = $1.to_i
  ARGV.delete(item)
end

# look for resolution arg
xres, yres = 800, 800
ARGV.grep(/^(\d+)[x\*](\d+$)/) do |item|
  xres, yres = $1.to_i, $2.to_i
  ARGV.delete(item)
end

#look for timeout arg
timeout = 50000
ARGV.grep( /^-timeout=(\d+)/ )do |item|
  timeout = $1.to_i
  ARGV.delete(item)
end

range_start = 1
ARGV.grep( /^-begin=(\d+)/ )do |item|
  range_start = $1.to_i
  ARGV.delete(item)
end

range_end = 1
ARGV.grep( /^-end=(\d+)/ )do |item|
  range_end = $1.to_i
  ARGV.delete(item)
end

#look for teams arg
team_count = 8
ARGV.grep( /^-teams=(\d)/ )do |item|
  x = $1.to_i
  team_count = x if x > 0 && x < 8
  ARGV.delete(item)
end
teams = Array.new([team_count, ARGV.size].min){ [] }

usage if ARGV.size > 8 || ARGV.empty?

@robots_loaded = []
c = 0
team_divider = (ARGV.size / teams.size.to_f).ceil
ARGV.map! do |robot|
  begin
    begin
      require robot.downcase
    rescue LoadError
    end
    begin
      require robot
    rescue LoadError
    end
    @robots_loaded<<robot
  rescue Exception => error
    puts 'Error loading ' + robot + '!'
    warn error
    usage
  end
  in_game_name = File.basename(robot).sub(/\..*$/, '')
  in_game_name[0] = in_game_name[0,1].upcase
  in_game_name
end

for variable_element in range_start..range_end do
  @win_record = []
  previous_seed = 0
  for trial in 1..number_of_rounds do
    seed = Time.now.to_i + Process.pid
    while (seed == previous_seed)
      seed = Time.now.to_i + Process.pid
    end
    previous_seed = seed
    print "Game #{trial}: [#{seed}]"
    battlefield = Battlefield.new xres*2, yres*2, timeout, seed
    c = 0
    @robots_loaded.each do |robot|
      in_game_name = File.basename(robot).sub(/\..*$/, '')
      in_game_name[0] = in_game_name[0,1].upcase
      team = c / team_divider
      c += 1
      robotrunner = RobotRunner.new(Object.const_get(in_game_name).new, battlefield, team)
      battlefield << robotrunner
    end

    run(battlefield, trial)
  end
  $stderr.print "Trial #{variable_element}  -- "
  print_aggregate_results number_of_rounds
end
