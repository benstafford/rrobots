#require File.expand_path("../project_euler", __FILE__)
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../robots/')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../robots/NewInvader')

require 'numeric'
require 'battlefield'
require 'bullet'
require 'explosion'
require 'NervousDuck'
require 'SittingDuck'
require 'robot'
require 'Goodness'