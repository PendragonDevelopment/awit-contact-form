before do
  content_type :json
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['POST']
end

set :protection, false
set :public_dir, Proc.new { File.join(root, "_site") }

post '/send_email' do
  res = Pony.mail(
    :from => params[:name] + "<" + params[:email] + ">",
    :to => 'pendragondevelopment@gmail.com',
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