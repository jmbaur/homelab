Config
  { font = "xft:Hack:pixelsize=14"
  , commands =
      [ Run Cpu [] 10
      , Run Memory ["-t", "Mem: <usedratio>%"] 10
      , Run Swap [] 10
      , Run Date "%T %F" "date" 10
      , Run Battery ["-t", "Bat: <left>%"] 10
      , Run StdinReader
      ]
  , sepChar = "%"
  , alignSep = "><"
  , template = "%StdinReader%><%cpu% | %memory% | %swap% | %battery% | %date%"
  }
