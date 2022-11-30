package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"
)

var (
	osc9                     = "\033]9;%s: %s\007"
	osc777                   = "\033]777;notify;%s;%s\007"
	tmuxSequenceFormatString = "\033Ptmux;\033%s\033\\"
	_, insideTmux            = os.LookupEnv("TMUX")
	useOsc9                  = false
)

func notifyf(format string, a ...any) {
	var wrap string
	if insideTmux {
		if useOsc9 {
			wrap = fmt.Sprintf(tmuxSequenceFormatString, osc9)
		} else {
			wrap = fmt.Sprintf(tmuxSequenceFormatString, osc777)
		}
	} else {
		if useOsc9 {
			wrap = osc9
		} else {
			wrap = osc777
		}
	}
	fmt.Printf(wrap, "pomo", fmt.Sprintf(format, a...))
}

func printf(format string, a ...any) {
	fmt.Printf("\033[2K")
	fmt.Printf("\033[100D")
	fmt.Printf(format, a...)
}

func pomo(status string, d time.Duration) {
	notifyf(status)
	printf(status)
	fmt.Printf("\n")
	ticker := time.NewTicker(1 * time.Second)
	done := make(chan bool)
	start := time.Now()
	go func() {
		for {
			select {
			case t := <-ticker.C:
				diff := t.Sub(start)
				left := (d - diff).Round(1 * time.Second)
				if left == 5*time.Second {
					notifyf("5 seconds left!")
				}
				printf("%s", left)
			case <-done:
				return
			}
		}
	}()
	time.Sleep(d)
	ticker.Stop()
	done <- true
	fmt.Printf("\033[2K")
	fmt.Printf("\033[1A")
}

const (
	timeout int = iota
	keepGoing
	stop
)

func main() {
	flag.BoolVar(&useOsc9, "osc9", false, "Use OSC9 instead of OSC777")
	flag.Parse()

main:
	for {
		for i := 0; i < 4; i++ {
			pomo("work!", 25*time.Second)
			pomo("break!", 5*time.Second)
		}
		pomo("long break!", 30*time.Second)

		status := make(chan int)

		go func(status chan int) {
			printf("do you want to keep going? [y/N] ")
			var answer string
			if _, err := fmt.Scanln(&answer); err != nil {
				log.Fatal(err)
			}
			fmt.Printf("\033[2K")
			fmt.Printf("\033[1A")

			if strings.HasPrefix(strings.ToLower(answer), "y") {
				status <- keepGoing
			} else {
				status <- stop
			}
		}(status)

		for {
			notifyf("do you want to keep going?")
			go func(status chan int) {
				time.Sleep(30 * time.Second)
				status <- timeout
			}(status)

			switch <-status {
			case keepGoing:
				continue main
			case stop:
				break main
			case timeout:
				continue
			}
		}
	}
	printf("goodbye!")
}
