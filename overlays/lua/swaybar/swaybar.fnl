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

(fn battery-percentage [dbus-conn]
  (local msg (ldbus.message.new_method_call :org.freedesktop.UPower
                                            :/org/freedesktop/UPower/devices/DisplayDevice
                                            :org.freedesktop.DBus.Properties
                                            :Get))
  (local iter (ldbus.message.iter.new))
  (msg:iter_init_append iter)
  (iter:append_basic :org.freedesktop.UPower.Device)
  (iter:append_basic :Percentage)
  ;; TODO(jared): validate return values of send_with_reply_and_block
  (let [(reply err) (dbus-conn:send_with_reply_and_block msg)]
    (if err
        (error err)
        (do
          (reply:iter_init iter)
          (local sub-iter (iter:recurse))
          (string.format "BAT: %s%%" (sub-iter:get_basic))))))

(local cq (cqueues.new))
(cq:wrap (fn []
           (local dbus-conn (ldbus.bus.get :system))
           (io.stdout:write (json.encode {:version 1}) "\n[")
           (io.stdout:flush)
           (while true
             (io.stdout:write (json.encode [{:full_text (battery-percentage dbus-conn)}
                                            {:full_text (os.date "%D %T")}])
                              ",")
             (io.stdout:flush)
             (cqueues.sleep 5))))

;; (cq:attach (jeejah.start {}))
(assert (cq:loop))
