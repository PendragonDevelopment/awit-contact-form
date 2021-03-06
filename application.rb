require 'sinatra'
require 'sinatra/base'
require 'rubygems'
require 'json'
require 'pony'
require 'erb'

class SmallPotato < Sinatra::Base
  before do
    content_type :json
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['POST']
  end

  Dir["./models/*.rb"].each { |file| require file }

  post '/send_email' do
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['POST']
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
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['POST']
    puts headers
    puts request
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