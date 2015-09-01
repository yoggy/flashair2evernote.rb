flashair2evernote.rb
====

![FlashAir & MDS-820W](https://farm1.staticflickr.com/693/21033925306_0f6e52650e_n.jpg)

How to use
----
Configuration for Raspberry Pi Model B+ / Raspberry Pi 2 Model B

    $ sudo -i
    # wpa_passphrase flashair_ssid >> /etc/wpa_supplicant/wpa_supplicant.conf
    **** enter passphrase ****

    $ sudo apt-get install ruby
    $ sudo gem install mail
    
    $ mkdir -p ~/work/
    $ cd ~/work/
    $ git clone https://github.com/yoggy/flashair2evernote.rb.git

    $ cd ~/work/flashair2evernote.rb
    $ cp config.yaml.sample config.yaml
    $ vi config.yaml

        gmail_username:         username@gmail.com                   <- edit this lines
        gmail_password:         password                             <-
        evernote_mail:          evernote.post.address@m.evernote.com <-
        evernote_notebook_name: note                                 <- 
        flashair_list_url:      http://192.168.0.1/command.cgi?op=100&DIR=/DCIM/101PHOTO
        flashair_download_url:  http://192.168.0.1/DCIM/101PHOTO
    
    $ ./flashair2evernote.rb

For supervisord
----

     $ sudo apt-get install supervisor
     $ cd ~/work/flashair2evernote.rb/
     $ sudo cp flashair2evernote.conf.sample /etc/supervisor/conf.d/flashair2evernote.conf
     $ sudo vi /etc/supervisor/conf.d/flashair2evernote.conf
       (fix path, username, etc...)
     $ sudo supervisorctl reread
     $ sudo supervisorctl add flashair2evernote
     $ sudo supervisorctl status
     flashair2evernote                  RUNNING    pid 8192, uptime 0:00:30



Copyright and license
----
Copyright (c) 2015 yoggy

Released under the [MIT license](LICENSE.txt)

