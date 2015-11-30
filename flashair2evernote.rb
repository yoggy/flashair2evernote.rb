#!/usr/bin/ruby
#
#  flashair2evernote.rb
#
require 'open-uri'
require 'csv'
require 'pstore'
require 'logger'
require 'fileutils'
require 'mail'
require 'yaml'
require 'ostruct'

$conf = OpenStruct.new(YAML.load_file(File.dirname($0) + '/config.yaml'))

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

$db = PStore.new(File.dirname($0) + '/.history.pstore')
$tmp_dir = File.dirname($0) + '/.tmp/'
FileUtils.mkdir_p($tmp_dir)

def setup_wlan0
  # ifup wlan0
  system("sudo ifdown wlan0 >/dev/null 2>&1")
  sleep 1
  system("sudo ifup wlan0 >/dev/null 2>&1")
  sleep 1
  
  # check local ip address
  has_local_ip = false
  20.times do |n|
    local_ip = `/sbin/ifconfig wlan0 | grep 192.168.0`
    if local_ip != ""
      has_local_ip = true
      break
    end
    sleep 10
  end

  has_local_ip
end

def ping(addr)
  rv = `ping -W 1 -c 1 #{addr} 2>&1 | grep from`

  return false if rv.nil? || rv.size == 0

  true
end

def get_files
  files = nil
  begin
    str = open($conf.flashair_list_url).read
    csv = CSV.parse(str)

    files = []
    csv.each do |l|
      next if l[0] == "WLANSD_FILELIST"
      files << l[1]
    end
  rescue Exception => e
    $log.error e
    return nil
  end
  files.sort!

  return files
end

def get_history
  h = nil
  $db.transaction do
    h = $db["history"]
  end
  h = [] if h.nil?
  h 
end

def check_files(old, now)
  diff = []

  now.each do |f|
    diff << f if !old.include?(f)
  end

  diff
end

def append_history(f)
  $db.transaction do
    h = $db["history"]
    if h.nil?
      $db["history"] = [f]
    else
      h = $db["history"]
      h << f if !h.include?(f)
      h.sort!
      $db["history"] = h
    end
  end
end

def download(f)
  path = $tmp_dir + "/" + f
  url = $conf.flashair_download_url + "/" + f

  data = open(url).read()
  f = open(path, "wb")
  f.write(data)
  f.flush
  f.close

  return path
end

def send_mail(f, path)
  mail = Mail.new do
    from    $conf.gmail_username
    to      $conf.evernote_mail
    subject "#{f} @" + $conf.evernote_notebook_name
    body    "this image was uploaded by flashair2evernote.rb ."
    add_file path
  end

  mail.delivery_method(:smtp,{
    :address              => "smtp.gmail.com",
    :port                 => 587,
    :domain               => "smtp.gmail.com",
    :user_name            => $conf.gmail_username,
    :password             => $conf.gmail_password,
    :authentication       => :plain,
    :enable_starttls_auto => true
  })

  mail.deliver
end

def upload(f)
  $log.info "upload() : file=#{f}"
  begin
    path = download(f)
    send_mail(f, path)
    FileUtils.rm_rf(path)
    append_history(f)
  rescue Exception => e
    $log.error e
  end
end

def main
  loop do
    $log.info "check wifi connection..."
    break if setup_wlan0 == true
  end

  loop do
    break if ping("192.168.0.1") == false

    $log.info "check new files on FlashAir..."

    now = get_files
    if now.nil?
      $log.warn "get_files() : connection failed..retry connecting..."
      break
    end

    if now.size == 0
      sleep 1
      next
    end

    old = get_history

    diff = check_files(old, now)
    if !diff.nil? && diff.size > 0
      diff.each do |f|
        upload(f)
      end
    end

    sleep 3
  end
end

if __FILE__ == $0
  loop do
    begin
      main
      sleep 1
    rescue Exception => e
      exit(0) if e.class.to_s == "Interrupt"
      $log.error e
    end
  end
end

