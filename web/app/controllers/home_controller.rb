class HomeController < ApplicationController
  def index
    # system "#{ tabi } allow #{ client_MAC }" if client_MAC
  end


  ##############################################################################
  private
  ##############################################################################


  def tabi
    File.join File.dirname( __FILE__ ), "../../../bin/tabi"
  end


  def client_MAC
    arp_output = `arp -n #{ request.env[ "HTTP_X_FORWARDED_FOR" ] }`.split( "\n" )
    if arp_output.size == 2
      arp_output[ 1 ].split[ 2 ]
    else
      nil
    end
  end
end
