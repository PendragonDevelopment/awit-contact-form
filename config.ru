require 'rubygems'
require 'sinatra'
require 'json'
require 'rack/recaptcha'
require 'pony'

use Rack::Recaptcha, :public_key => '6Lf0qAETAAAAAFgLGVZ2AjlyKGezQ3Rt4ggxDiQj', :private_key => '6Lf0qAETAAAAAOqisvT5YVIYD89eBvta-Jgvm_xz'
helpers Rack::Recaptcha::Helpers

require './application'
run Sinatra::Application