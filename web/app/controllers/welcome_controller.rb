class WelcomeController < ApplicationController
  def index
    arp_output = `arp -n #{ request.env[ "HTTP_X_FORWARDED_FOR" ] }`.split( "\n" )
    if arp_output.size == 2
      @client_mac = arp_output[ 1 ].split[ 2 ]
    else
      @client_mac = nil
    end
  end
end
