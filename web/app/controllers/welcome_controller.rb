# -*- coding: utf-8 -*-
class WelcomeController < ApplicationController
  def index
    if user_signed_in?
      arp_output = `arp -n #{ request.remote_ip }`.split( "\n" )
      if arp_output.size == 2
        user_mac = arp_output[ 1 ].split[ 2 ]
        # TODO: ハードコードしているのをやめる
        system "ssh yasuhito@192.168.0.254 /home/yasuhito/play/tabi/bin allow #{ user_mac }"
      end
    end
  end
end
