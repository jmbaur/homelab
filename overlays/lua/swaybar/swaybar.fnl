(local auxlib (require :cqueues.auxlib))
(local cqueues (require :cqueues))
(local io (require :io))
(local json (require :dkjson))
(local ldbus (require :ldbus))
(local os (require :os))
;; (local jeejah (require :jeejah))

(set _G.assert auxlib.assert)
(set _G.tostring auxlib.tostring)
(set coroutine.resume auxlib.resume)
(set coroutine.wrap auxlib.wrap)

(fn dbus-get-property [dest object interface property service dbus-conn]
  (local msg (ldbus.message.new_method_call dest object interface :Get))
  (local iter (ldbus.message.iter.new))
  (msg:iter_init_append iter)
  (iter:append_basic service)
  (iter:append_basic property)
  (let [(reply err) (dbus-conn:send_with_reply_and_block msg)]
    (if err
        (error err)
        (do
          (reply:iter_init iter)
          (local sub-iter (iter:recurse))
          (sub-iter:get_basic)))))

(fn online [dbus-conn]
  (string.format "NET: %s"
                 (dbus-get-property :org.freedesktop.network1
                                    :/org/freedesktop/network1
                                    :org.freedesktop.DBus.Properties
                                    :OnlineState
                                    :org.freedesktop.network1.Manager dbus-conn)))

(fn timezone [dbus-conn]
  (string.format "TZ: %s"
                 (dbus-get-property :org.freedesktop.timedate1
                                    :/org/freedesktop/timedate1
                                    :org.freedesktop.DBus.Properties :Timezone
                                    :org.freedesktop.timedate1 dbus-conn)))

(fn battery-percentage [dbus-conn]
  (string.format "BAT: %s%%"
                 (dbus-get-property :org.freedesktop.UPower
                                    :/org/freedesktop/UPower/devices/DisplayDevice
                                    :org.freedesktop.DBus.Properties :Percentage
                                    :org.freedesktop.UPower.Device dbus-conn)))

(local cq (cqueues.new))
(cq:wrap (fn []
           (local dbus-conn (ldbus.bus.get :system))
           (io.stdout:write (json.encode {:version 1}) "\n[")
           (io.stdout:flush)
           (while true
             (io.stdout:write (json.encode [{:full_text (battery-percentage dbus-conn)}
                                            {:full_text (online dbus-conn)}
                                            {:full_text (timezone dbus-conn)}
                                            {:full_text (os.date "%D %T")}])
                              ",")
             (io.stdout:flush)
             (cqueues.sleep 5))))

;; (cq:attach (jeejah.start {}))
(assert (cq:loop))
