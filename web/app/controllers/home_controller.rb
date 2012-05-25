class HomeController < ApplicationController
  def index
    logger.info "MAC address = #{ client_MAC }"
  end


  ##############################################################################
  private
  ##############################################################################


  def client_MAC
    arp_output = `arp -n #{ request.env[ "REMOTE_ADDR" ] }`.split( "\n" )
    if arp_output.size == 2
      arp_output[ 1 ].split[ 2 ]
    else
      nil
    end
  end
end
