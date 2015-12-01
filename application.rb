require 'sinatra'
require 'sinatra/base'
require 'rubygems'
require 'json'
require 'pony'
require 'erb'
require 'sinatra/json'
require 'sinatra/cross_origin'

class SmallPotato < Sinatra::Base
  configure do
    enable :cross_origin
  end

  ##### CONFIG #####
  set :allow_origin, "*"
  set :allow_methods, [:get, :post, :options]
  set :allow_credentials, true
  set :max_age, "1728000"
  set :expose_headers, ['Content-Type']
  set :root, File.dirname(__FILE__)

  Dir["./models/*.rb"].each { |file| require file }

  set :protection, false
  set :public_dir, Proc.new { File.join(root, "_site") }

  post '/send_email' do
    res = Pony.mail(
      :from => params[:name] + "<" + params[:email] + ">",
      :to => 'info@justsmallpotatoes.com',
      :subject => "Contact from website",
      :body => params[:message],
      :via => :smtp,
      :via_options => {
        :address              => 'smtp.mandrillapp.com',
        :port                 => '587',
        :user_name            => ENV['MANDRILL_USERNAME'],
        :password             => ENV['MANDRILL_PASSWORD'],
        :authentication       => :plain,
        :domain               => 'heroku.com'
      })
    content_type :json
    if res
      { :message => 'success' }.to_json
    else
      { :message => 'failure_email' }.to_json
    end
  end

  post '/send_order' do
    charge = Charge.new(ENV['STRIPE_KEY'])
    charge.newOrder(params[:token], params[:amount])
    template_path = "./email.html.erb"
    context = binding
    body = ERB.new(File.read(template_path)).result(context)
    res = Pony.mail(
      :from => 'no_reply@justsmallpotatoes.com',
      :to => 'info@justsmallpotatoes.com',
      :subject => "New order from website",
      :html_body => body,
      :via => :smtp,
      :via_options => {
        :address              => 'smtp.mandrillapp.com',
        :port                 => '587',
        :user_name            => ENV['MANDRILL_USERNAME'],
        :password             => ENV['MANDRILL_PASSWORD'],
        :authentication       => :plain,
        :domain               => 'heroku.com'
      })
    content_type :json
    if res
      { :message => 'success' }.to_json
    else
      { :message => 'failure_email' }.to_json
    end
  end

  not_found do
    File.read('_site/404.html')
  end

  get '/*' do
    file_name = "_site#{request.path_info}/index.html".gsub(%r{\/+},'/')
    if File.exists?(file_name)
      File.read(file_name)
    else
      raise Sinatra::NotFound
    end
  end
end