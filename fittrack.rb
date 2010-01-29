%w(rubygems sinatra dm-core dm-validations dm-timestamps rack-flash httparty haml).each {|r| require r}
enable :sessions
use Rack::Flash

class Twitter
  include HTTParty
  base_uri "twitter.com"
  basic_auth 'USERNAME', 'PASSWORD'
end

class Record
  include DataMapper::Resource

  property :id,         Serial    # primary serial key
  property :norun,      Boolean
  property :distance,   Float
  property :time,       Integer
  property :date,       Date
  property :created_at, DateTime
  property :updated_at, DateTime

  def week
    self.date.strftime('%w')
  end
  
  def date_f
    self.date.strftime('%a %d %b')
  end
end

configure do
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/fittrack.sqlite3"))
  DataMapper.auto_upgrade!
end

get '/' do
  @records = Record.all(:order => [ :date.asc ])
  haml :index
end

post '/' do
  @record = Record.new()
  params[:norun] == "on" ? @record.norun = true : @record.norun = false
  @record.distance = params[:distance].to_f
  @record.time = params[:time].to_i
  @record.date = Date.today
  
  if @record.save
    flash[:message] = "Record Saved"
    unless @record.norun
      message = "Ran #{@record.distance} miles in #{@record.time} mins today"
      tweet = Twitter.post("/statuses/update.json", :query => {:status => message})
    end
    redirect '/'
  else
    flash[:message] = "The event couldn't be saved."
    redirect '/'
  end
end