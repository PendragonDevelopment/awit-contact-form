require 'sinatra'
require 'sinatra/base'
require 'rubygems'
require 'json'
require 'pony'
require 'erb'

class SmallPotato < Sinatra::Base
  set :protection, false

  Dir["./models/*.rb"].each { |file| require file }

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
      { :message => 'success', :charge => charge }.to_json
    else
      { :message => 'failure_email' }.to_json
    end
  end

  not_found do
    File.read('_site/404.html')
  end

end