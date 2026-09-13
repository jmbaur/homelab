(local auxlib (require :cqueues.auxlib))
(local condition (require :cqueues.condition))
(local cqueues (require :cqueues))
(local io (require :io))
(local jeejah (require :jeejah))
(local json (require :dkjson))
(local ldbus (require :ldbus))
(local os (require :os))
(local socket (require :socket))

(local unpack (or table.unpack _G.unpack))

(set _G.assert auxlib.assert)
(set _G.tostring auxlib.tostring)
(set coroutine.resume auxlib.resume)
(set coroutine.wrap auxlib.wrap)

(fn log [...]
  (let [args [...]
        n (select "#" ...)]
    (io.stderr:write (table.concat (fcollect [i 1 n] (tostring (. args i)))
                                   "\t") "\n")))

;; stdout belongs to swaybar's json protocol, so send anything jeejah prints to
;; the journal instead. Code evaluated over nrepl gets its own print, pointed at
;; the connected client.
(set _G.print log)

;; signalled when a dbus signal (or the repl) invalidates a block, so the bar
;; redraws right away instead of waiting for the next tick
(local wake (condition.new))

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
  (string.format "NET: %s" (case (dbus-get-property :org.freedesktop.NetworkManager
                                                    :/org/freedesktop/NetworkManager
                                                    :org.freedesktop.DBus.Properties
                                                    :State
                                                    :org.freedesktop.NetworkManager
                                                    dbus-conn)
                             ; https://www.networkmanager.dev/docs/api/latest/nm-dbus-types.html#NMState
                             10
                             :offline
                             20
                             :disconnecting
                             30
                             :disconnecting
                             40
                             :connecting
                             50
                             :offline
                             60
                             :online*
                             70
                             :online
                             _
                             :unknown)))

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

(fn clock []
  (os.date "%D %T"))

;; The environment nrepl sessions evaluate in, seeded with the bar's own
;; functions. Redefining one of these over the connection -- C-M-x on the (fn
;; battery-percentage ...) form in emacs, say -- is what makes the bar pick up a
;; new implementation, so the handlers a block might want to call have to be
;; reachable by name in here.
(local nrepl-env {: battery-percentage
                  : clock
                  : dbus-get-property
                  : log
                  : online
                  : timezone})

;; fennel's repl keeps top-level (fn foo ...) definitions in ___replLocals___
;; and puts (global foo ...) straight in the env, both under the name as written
(fn resolve [name]
  (or (?. nrepl-env :___replLocals___ name) (. nrepl-env name)))

;; The one piece of mutable state, handed to nrepl sessions as `swaybar`. Blocks
;; are rendered left to right; a block's :fn is called with the system bus
;; connection and returns the text to display.
;;
;; :fn is either a function or, as the blocks below use, the name of one. A name
;; is resolved in the nrepl environment on every tick, so re-evaluating the
;; definition of a handler over the connection changes what the bar runs -- that
;; is the whole point of the indirection. (The handler is the unit that is late
;; bound: a helper it calls, dbus-get-property say, was captured when the
;; handler was defined, so redefine the handler too after changing one.)
;;
;; The name in the repl is the live implementation, which is what to hold on to
;; when wrapping one rather than replacing it:
;;
;;   (local plain timezone)
;;   (fn timezone [conn] (.. "\u{1f552} " (plain conn)))
;;
;; Everything else is a plain table to edit, swaybar.blocks a plain array:
;;
;;   (table.insert swaybar.blocks {:name :load :fn :load-average})
;;   (table.remove swaybar.blocks 3)
;;   (tset (swaybar.block :battery) :fn #(.. "x"))     ; swaybar.block finds one
;;
;; Match rules follow whatever the blocks say on the next tick, so a block can
;; be added, removed or repointed at another object this way.
;;
;; A block with a :path is driven by dbus: the bar subscribes to signals from
;; that object and only calls :fn again when one arrives. A block without one
;; (the clock) is called every :interval seconds.
(local swaybar {:interval 1
                :blocks [{:name :battery
                          :fn :battery-percentage
                          :path :/org/freedesktop/UPower/devices/DisplayDevice}
                         {:name :network
                          :fn :online
                          :path :/org/freedesktop/NetworkManager}
                         {:name :timezone
                          :fn :timezone
                          :path :/org/freedesktop/timedate1}
                         {:name :clock :fn :clock}]
                ;; set once the bar is up, along with dbus-get-property these
                ;; are enough to write new blocks from the repl
                :dbus-conn nil
                : dbus-get-property
                ;; jeejah swaps out io for the nrepl session, keep the real one
                ;; around so repl blocks can read from /proc and friends
                : io
                : log})

(set nrepl-env.swaybar swaybar)

(fn block-fn [block]
  (if (= (type block.fn) :string) (resolve block.fn) block.fn))

(fn render-block [block handler dbus-conn]
  (case (if (= (type handler) :function)
            (pcall handler dbus-conn)
            (values false
                    (string.format "no handler named %s" (tostring block.fn))))
    (true text) (do
                  (set block.last-error nil)
                  {:name (tostring block.name) :full_text (tostring text)})
    (_ err) (do
              ;; only complain when the error changes, the bar keeps ticking
              (when (not= block.last-error err)
                (set block.last-error err)
                (log "swaybar: block" block.name "failed:" err))
              {:name (tostring block.name)
               :full_text (string.format "%s: error" block.name)
               :color "#ff0000"})))

;; everything an object emits, rather than picking out PropertiesChanged: some
;; services (NetworkManager) announce changes with signals of their own as well
(fn signal-match [path]
  (string.format "type='signal',path='%s'" path))

;; ldbus has no accessor for the connection's socket, and libdbus only offers it
;; through the watch api; both watches it hands out are for the same socket
(var dbus-fd nil)

;; connect lazily, so that a system bus that is not up yet costs one bad tick
;; rather than the whole bar
(fn system-bus []
  (when (not swaybar.dbus-conn)
    (let [conn (or (ldbus.bus.get :system)
                   (error "no connection to the system bus"))]
      (conn:set_watch_functions #(do
                                   (set dbus-fd ($1:get_unix_fd))
                                   true) #true
                                #true)
      (set swaybar.dbus-conn conn)))
  swaybar.dbus-conn)

;; the paths the bar has match rules installed for
(local matched {})

;; blocks are just a table someone edits from the repl, so rather than
;; subscribing and unsubscribing as that happens, bring the rules we hold in
;; line with the paths the blocks ask for
(fn reconcile-matches [dbus-conn]
  (let [wanted (collect [_ block (ipairs swaybar.blocks)]
                 (when block.path
                   (values block.path true)))]
    (each [path (pairs wanted)]
      (when (not (. matched path))
        (ldbus.bus.add_match dbus-conn (signal-match path))
        (tset matched path true)))
    (each [path (pairs matched)]
      (when (not (. wanted path))
        (ldbus.bus.remove_match dbus-conn (signal-match path))
        (tset matched path nil)))))

(fn block-json [block dbus-conn]
  (let [handler (block-fn block)]
    ;; a dbus-driven block keeps its last value until a signal invalidates it,
    ;; except that a handler or a path that is not the one it last rendered with
    ;; -- a definition re-evaluated over nrepl -- always takes effect here
    (when (or block.dirty (not block.json) (not block.path)
              (not= block.rendered-fn handler)
              (not= block.rendered-path block.path))
      (set block.dirty false)
      (set block.rendered-fn handler)
      (set block.rendered-path block.path)
      (set block.json (render-block block handler dbus-conn)))
    block.json))

;; blocks by name, rather than by their position in swaybar.blocks
(set swaybar.block
     (fn [name]
       (accumulate [found nil _ block (ipairs swaybar.blocks) &until found]
         (when (= (tostring block.name) (tostring name)) block))))

;; force a re-read of every block, for after poking at them by hand
(set swaybar.refresh (fn []
                       (each [_ block (ipairs swaybar.blocks)]
                         (set block.dirty true))
                       (wake:signal)))

(fn render []
  (let [dbus-conn (system-bus)]
    (reconcile-matches dbus-conn)
    (icollect [_ block (ipairs swaybar.blocks)]
      (block-json block dbus-conn))))

(fn emit [blocks]
  (io.stdout:write (json.encode blocks) ",")
  (io.stdout:flush))

;; sway wants the protocol header before anything else, and getting it out
;; before any of the work below means nothing can delay the bar appearing
(io.stdout:write (json.encode {:version 1}) "\n[")
(io.stdout:flush)

;; take whatever the bus has queued for us; a signal from an object some block
;; subscribed to marks that block for a re-read
(fn drain-bus [dbus-conn]
  (dbus-conn:read_write 0)
  (var dirty false)
  (var msg (dbus-conn:pop_message))
  (while msg
    (let [path (msg:get_path)]
      (each [_ block (ipairs swaybar.blocks)]
        (when (= block.path path)
          (set block.dirty true)
          (set dirty true))))
    (set msg (dbus-conn:pop_message)))
  (when dirty
    (wake:signal)))

(local cq (cqueues.new))

(var last-render-error nil)

(cq:wrap (fn []
           (while true
             ;; a broken block list from the repl should not take the bar down
             (case (pcall render)
               (true blocks) (do
                               (set last-render-error nil)
                               (emit blocks))
               (_ err) (do
                         (when (not= last-render-error err)
                           (set last-render-error err)
                           (log "swaybar: render failed:" err))
                         (emit [{:name :swaybar
                                 :full_text (tostring err)
                                 :color "#ff0000"}])))
             ;; rendering reads from the bus, and can leave signals sitting in
             ;; libdbus' queue where they no longer make the socket readable
             (pcall drain-bus swaybar.dbus-conn)
             (wake:wait (or (tonumber swaybar.interval) 1)))))

(fn watch-bus []
  (let [dbus-conn (system-bus)]
    ;; the timeout is only a backstop; signals normally arrive as a wakeup here
    (if dbus-fd
        (cqueues.poll {:pollfd dbus-fd :events :r} 5)
        (cqueues.sleep 1))
    (drain-bus dbus-conn)))

(cq:wrap (fn []
           (while true
             (case (pcall watch-bus)
               (false err) (do
                             (log "swaybar: watching the bus failed:" err)
                             (cqueues.sleep 5))))))

;; Drive jeejah's accept/read loop off cqueues rather than letting it block the
;; process in socket.select, so the bar keeps updating while nobody is connected.
(fn cq-select [sockets]
  (let [pollable (icollect [_ sock (ipairs sockets)]
                   (let [fd (sock:getfd)]
                     (when (and fd (>= fd 0)) {:pollfd fd :events :r})))]
    (if (next pollable)
        (cqueues.poll (unpack pollable))
        (cqueues.sleep 0.1))
    (socket.select sockets nil 0)))

(local nrepl-port (tonumber (or (os.getenv :SWAYBAR_NREPL_PORT) 7888)))
(local nrepl-address (or (os.getenv :SWAYBAR_NREPL_ADDRESS) "::1"))

;; SWAYBAR_NREPL_PORT=0 turns the repl off
(when (and nrepl-port (> nrepl-port 0))
  (cq:wrap (fn []
             ;; jeejah.start only returns by erroring, e.g. when the port is
             ;; already taken by another bar; that is not fatal to the bar
             (case (pcall jeejah.start
                          {:address nrepl-address
                           :port nrepl-port
                           :select cq-select
                           :env nrepl-env})
               (_ err) (log "swaybar: nrepl server stopped:" err)))))

(assert (cq:loop))
