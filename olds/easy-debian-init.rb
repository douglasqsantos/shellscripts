#!/usr/bin/env ruby
# encoding: UTF-8
#-------------------------------------------------------------------------
# Easy-Debian
#
# Site  : http://wiki.douglasqsantos.com.br
# Author : Douglas Q. dos Santos <douglas.q.santos@gmail.com>
# Management: Douglas Q. dos Santos <douglas.q.santos@gmail.com>
# GitHub: https://github.com/douglasqsantos/easy-debian
#
#-------------------------------------------------------------------------
# Note: This Ruby Script set up the initial configuration to Debian
# where install the needed packets and configure some packets
#-------------------------------------------------------------------------
# History:
#
# Version 1.0:
# Data: 29/12/2015
# Description: Set up the initial configuration of Debian GNU/Linux
# set up the repositories and install some packets
#--------------------------------------------------------------------------
#
# How to use: https://github.com/douglasqsantos/easy-debian
#
#--------------------------------------------------------------------------
#License: MIT license http://opensource.org/licenses/MIT
#--------------------------------------------------------------------------

# Core library from Ruby
require 'rubygems'

# Used as extension of file library
require 'fileutils'

# Used to work with http protocol
require 'net/http'
require 'open-uri'


# Module that controls the colors used
module Tty extend self

  def black; bold 30; end
  def red; bold 31; end
  def green; bold 32; end
  def yellow; bold 33; end
  def blue; bold 34; end
  def purple; bold 35; end
  def cyan; bold 36; end
  def white; bold 39; end
  def grey; bold 38; end
  def reset; escape 0; end
  def bold n; escape "1;#{n}" end
  def underline n; escape "4;#{n}" end
  def escape n; "\033[#{n}m" if STDOUT.tty? end

end

# Module to handle http requests
module Crawler
  # Usage examples:
  # Without proxy
  #c = Crawler::NetHttp.new()
  # Using only server and port for proxy connection
  #c = Crawler::NetHttp.new("10.0.0.254", "3128")
  # Using server, port, user and password for proxy connection
  #c = Crawler::NetHttp.new("<http proxy URL>", "<port >", "Proxy user name", "Proxy Password")
  class NetHttp
    def initialize(proxy_host=nil, proxy_port=nil, proxy_user = nil, proxy_pass = nil)
      @proxy_host =  proxy_host;
      @proxy_port =  proxy_port;
      @proxy_user =  proxy_user;
      @proxy_pass =  proxy_pass;
    end

    def request_response(uri_str, limit = 10)
      begin
        http = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pass)
        result = http.get_response(URI.parse(uri_str))
        case result
          when Net::HTTPSuccess
          then  puts "#{Tty.blue}The file: #{Tty.white}#{uri_str}#{Tty.blue} was downloaded and saved! #{Tty.reset}"
          result
          when Net::HTTPRedirection then request_response(result['location'], limit - 1)
          else
            result.error!
        end
      rescue Exception => e
          puts "#{Tty.red} #{e.message} #{Tty.white}#{uri_str} #{Tty.reset}"
          return false
      end
    end
  end
end


module EasyDebian
  # Usage examples:
  # Usage examples:
  # Without proxy
  # new_deb = EasyDebian::Core.new()
  # Using only server and port for proxy connection
  # new_deb = EasyDebian::Core.new("10.0.0.254", "3128")
  # Using server, port, user and password for proxy connection
  # new_deb = EasyDebian::Core.new("<http proxy URL>", "<port >", "Proxy user name", "Proxy Password")

  class Core

    def initialize(proxy_host=nil, proxy_port=nil, proxy_user = nil, proxy_pass = nil)
      @proxy_host =  proxy_host;
      @proxy_port =  proxy_port;
      @proxy_user =  proxy_user;
      @proxy_pass =  proxy_pass;

      # Check if the script is running as root user
      abort "#{Tty.red}Needs to run this as root!#{Tty.reset}" if Process.uid != 0
      puts "#{Tty.blue}This script is running with the following PID: #{Tty.white}"  + Process.pid.to_s + "#{Tty.reset}"
    end

    # Method to call the sleep command and wait for a given seconds
    def sleep_time(time)
      system "sleep #{time}s"
    end

    # Method to install packages
    # TODO: needs to validate if the mode is interactive or not
    def install_packages(packages,comment)
      aptitude = '/usr/bin/aptitude'
      no_interactive = 'export DEBIAN_FRONTEND=noninteractive'

      puts "#{Tty.blue}Updating Repositories #{Tty.reset}"
      update_repo = system "#{aptitude} update"
      sleep_time(2)

      if update_repo
        puts "#{Tty.blue}Repositories Updated! #{Tty.reset}"
      else
        puts "#{Tty.red}Repositories Not Updated! #{Tty.reset}"
      end

      puts "#{Tty.blue}Updating the System #{Tty.reset}"
      update_system = system ("#{no_interactive}; #{aptitude} safe-upgrade -y")
      sleep_time(2)

      if update_system
        puts "#{Tty.blue}System Updated! #{Tty.reset}"
      else
        puts "#{Tty.red}System Not Updated! #{Tty.reset}"
      end

      puts "#{Tty.blue}Installing Packages: #{Tty.white}#{comment} #{Tty.reset}"
      install_pkgs = system ("#{no_interactive}; #{aptitude} install #{packages} -y")
      sleep_time(2)

      if install_pkgs
        puts "#{Tty.blue}Packages: #{Tty.white}#{comment} #{Tty.blue}Installed! #{Tty.reset}"
      else
        puts "#{Tty.red}Packages Not Installed! #{Tty.reset}"
        sleep_time(2)
      end
    end

    # Method to execute a command and return its result
    # Used to get system information such as architecture and another stuffs
    def exec_command(command)
      output = `#{command}`.chomp
      result=$?.success?
      unless result
        puts "#{Tty.red}Command with some problem! #{Tty.reset}"
      end
      # If no problems with the command line return
      return output
    end

    # Method get remote files from the github so far, but it will be extended
    # in the future.
    def download_files(path,url)
      c = Crawler::NetHttp.new(@proxy_host, @proxy_port, @proxy_user, @proxy_pass)
      result = c.request_response("#{url}")
      if result
        File.open("#{path}", 'w') { |file| file.write(result.body) }
      end
    end

    # Method to create automatically backup of the files before overwrite them.
    def check_file_exits(file)
      if File.exists?(file)
        check_mv = FileUtils.move(file,"#{file}.bkp")
        check_status(check_mv,"Creating a backup of file: #{Tty.white} #{file} #{Tty.reset}")
      end
    end

    # Method to create automatically backup of the files before overwrite them.
    def check_dir_exits(dir)
      if Dir.exists?(dir)
        if Dir.exists?("#{dir}.bkp")
          FileUtils.remove_dir("#{dir}.bkp")
        end
        check_mv = FileUtils.move(dir,"#{dir}.bkp")
        check_status(check_mv,"Creating a backup of directory: #{Tty.white} #{dir} #{Tty.reset}")
      end
    end

    # Method to handle the keyrings, here we can update a lot of keys only sending
    # as an array.
    def conf_keyrings(url,keys=[])
      gpg = '/usr/bin/gpg'
      keys.each do |key|
        import_key = system "#{gpg} --keyserver #{url} --recv-keys #{key}"
        check_status(import_key,"Updating #{Tty.white}GPG KEY: #{key}")
        sleep_time(2)
      end

      apt_key='/usr/bin/apt-key'
      add_pubring = system "#{apt_key} add ~root/.gnupg/pubring.gpg"
      check_status(add_pubring,"Adding the #{Tty.white}Pubring")
      #TODO: Adjust this method to work as bellow.
      docker_key = system("apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D")
      check_status(docker_key,"Adding the #{Tty.white}Docker Key")
      nginx_key = system("wget -qO- http://nginx.org/packages/keys/nginx_signing.key | apt-key add -")
      check_status(nginx_key,"Adding the #{Tty.white}Nginx Key")
    end

    # Method to convert the files to unix format, in some cases we need this feature
    # so is better has a method to handle it.
    def convert_file(files=[])
      dos2unix = '/usr/bin/dos2unix -q'
      files.each do |file|
        convert = system("#{dos2unix} #{file}")
        check_status(convert, "Converting the file: #{Tty.white}#{file}#{Tty.blue}")
      end
    end

    # Method to configure the crontab
    def conf_crontab(path)
      crontab = '/usr/bin/crontab'
      root_crontab = '/var/spool/cron/crontabs/root'
      # Added a new validation to make sure the root crontab configuration file exists.
      if File.exists?(root_crontab)
        bkp_crontab = system("#{crontab} -l > crontab.bkp")
        check_status(bkp_crontab, "Creating backup of #{Tty.white}crontab #{Tty.blue}")
        remove_crontab = system("#{crontab} -r")
        check_status(remove_crontab, "Removing the #{Tty.white}crontab configuration #{Tty.blue}")
      end
      add_crontab = system("#{crontab} #{path}")
      check_status(add_crontab, "Adding the new #{Tty.white}crontab configuration #{Tty.blue}")
    end

    # Method to get git repositories
    def get_git(path,url,comment,copy)
      git = '/usr/bin/git'
      cp = '/bin/cp'
      check_dir_exits(path)
      check_git = system("#{git} clone #{url} #{path}")
      check_status(check_git, "Cloning the #{Tty.white}#{comment}#{Tty.reset}")

      if Dir.exists?(path)
        if !copy.empty?
            if Dir.exists?(copy)
              copy_repo = system("#{cp} -Rfa #{path}/* #{copy}")
              check_status(copy_repo, "Copying the #{Tty.white}#{comment} #{Tty.blue}to #{Tty.white}#{copy} ")
            else
	      # If the firmware directory into /lib does not exists copy as it.
	      copy.chomp!('/')
	      copy_repo = system("#{cp} -Rfa #{path} #{copy}")
              check_status(copy_repo, "Copying the #{Tty.white}#{comment} #{Tty.blue}to #{Tty.white}#{copy} ")
            end
        end
      else
        puts "#{Tty.red}The directory #{Tty.white}#{path} #{Tty.red}does not exists!#{Tty.reset}"
      end

    end

    # Method to get the OS version, it will be used for the another scripts
    def check_os_version(os)
      cat = '/bin/cat'
      debian_version = '/etc/debian_version'
      centos_version = '/etc/redhat-relase'

      os_availables = %w(debian centos)
      if os_availables.include?(os.downcase)
        if os == 'debian'
          if File.exists?(debian_version)
            os_version = `#{cat} #{debian_version}`.chomp[/\d+/]
            case os_version
              when '7'
                return os_version_name = 'wheezy'
              when '8'
                return os_version_name = 'jessie'
              else
                puts "#{Tty.red}The Debian given does not have support yet! #{Tty.reset}"
            end
          else
            puts "#{Tty.red}The #{Tty.white}#{debian_version}#{Tty.red} does not exists! #{Tty.reset}"
          end
        elsif os == 'centos'
          if File.exists?(centos_version)
            os_version_name = `#{cat} #{centos_version}`.chomp[/\d+/]
          else
            puts "#{Tty.red}The #{Tty.white}#{centos_version}#{Tty.red} does not exists! #{Tty.reset}"
          end
        end
      else
        puts "#{Tty.red}The OS given does not have support yet! #{Tty.reset}"
      end
      return os_version_name
    end

    # Private methods that can be called only inside the Class
    private

    # Method to check the status of the commands
    def check_status(check,message)
      if check
        puts "#{Tty.blue}#{message} #{Tty.blue}executed successfully! #{Tty.reset}"
      else
        puts "#{Tty.red}#{message} #{Tty.red}executed with errors! #{Tty.reset}"
      end
    end

  ### END CLASS
  end

### END MODULE
end

### END OF THE CORE CLASS

# GLOBAL Variables
os_version = 'debian'

# Creating a new object to use the methods
# Usage examples:
# Without proxy
# new_deb = EasyDebian::Core.new()
# Using only server and port for proxy connection
# new_deb = EasyDebian::Core.new("10.0.0.254", "3128")
# Using server, port, user and password for proxy connection
# new_deb = EasyDebian::Core.new("<http proxy URL>", "<port >", "Proxy user name", "Proxy Password")
new_deb = EasyDebian::Core.new()

# Check the os Version
os_version_name = new_deb.check_os_version("#{os_version}")

# Defining some paths
repositories_path = '/etc/apt/sources.list'
vimrc_path = "#{Dir.home}/.vimrc"
bashrc_root_path = "#{Dir.home}/.bashrc"
bashrc_common_path = "/etc/skel/.bashrc"
crontab_path = '/tmp/crontab'
firmware_path = '/usr/src/firmware'
firmware_copy_path = '/lib/firmware/'

# Defining some urls
debian_rep_url = "https://raw.githubusercontent.com/douglasqsantos/easy-debian/master/sources-#{os_version_name}.list"
vimrc_url = 'https://raw.githubusercontent.com/douglasqsantos/easy-debian/master/vimrc'
nginx_vim_url  = 'https://raw.githubusercontent.com/douglasqsantos/easy-debian/master/nginx.vim'
bashrc_root_url = 'https://raw.githubusercontent.com/douglasqsantos/easy-debian/master/bashrc_root'
bashrc_common_url = 'https://raw.githubusercontent.com/douglasqsantos/easy-debian/master/bashrc_common'
crontab_url = 'https://raw.githubusercontent.com/douglasqsantos/easy-debian/master/crontab'
firmware_url = 'git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git'

# Getting the repositories
new_deb.download_files(repositories_path,debian_rep_url)

# Defining the architecture of box
arch = new_deb.exec_command('uname -r')

# Defining the packages that needs to be installed
case os_version_name
  when 'wheezy'
    pkgs = "vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf \
rsync build-essential linux-headers-#{arch} libncurses5-dev ntpdate postfix cmake sudo git makepasswd debian-archive-keyring \
ruby-dev pkg-config ruby-rmagick iproute2 iptables"
  when 'jessie'
    pkgs = "vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf \
rsync build-essential linux-headers-#{arch} libncurses5-dev ntpdate postfix cmake sudo git makepasswd debian-archive-keyring \
ruby-dev pkg-config ruby-rmagick iproute2 iptables"
end

# Updating the keyrings
new_deb.conf_keyrings('pgpkeys.mit.edu',keys=%w(1F41B907 A2098A6E 65558117 7BD9BF62 2C52609D))

# Installing the packages
new_deb.install_packages(pkgs,'Base Packages')

# Defining the tool packages that needs to be installed
case os_version_name
  when 'wheezy'
    tool_pkgs = 'atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm fish \
sdparm atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan'
  when 'jessie'
    tool_pkgs = 'atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm fish \
sdparm atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan'
end

# Installing the packages
new_deb.install_packages(tool_pkgs,'Tools Packages')

# Getting the vimrc
# Needs to check if the vim74 exists otherwise use the vim73 the older one
if Dir.exists?("/usr/share/vim/vim74/syntax/")
  nginx_vimrc_path = "/usr/share/vim/vim74/syntax/nginx.vim"
else
  nginx_vimrc_path = "/usr/share/vim/vim73/syntax/nginx.vim"
end

new_deb.download_files(vimrc_path,vimrc_url)

# Getting the nginx vim syntax
new_deb.download_files(nginx_vimrc_path,nginx_vim_url)

# Getting the bashrc configuration file
new_deb.download_files(bashrc_root_path,bashrc_root_url)
new_deb.download_files(bashrc_common_path,bashrc_common_url)

# Getting the crontab configuration file
new_deb.download_files(crontab_path,crontab_url)

# Configuring the crontab
new_deb.conf_crontab(crontab_path)

# Converting the file
new_deb.convert_file(files=["#{vimrc_path}","#{bashrc_root_path}","#{bashrc_common_path}","#{nginx_vimrc_path}"])

# Getting the new firmwares
new_deb.get_git(firmware_path,firmware_url,'Kernel Firmwares',firmware_copy_path)

# The last message
puts "#{Tty.white}Now you need to restart the machine to reload all the new configurations! #{Tty.reset}"
