{
:local targetFile "flash/backup.rsc"
:delay 15s
:local doStartBeep [:parse ":beep frequency=1000 length=300ms;:delay 150ms;:beep frequency=1500 length=300ms;"];
:local doFinishBeep [:parse ":beep frequency=1000 length=.6;:delay .5s;:beep frequency=1600 length=.6;:delay .5s;:beep frequency=2100 length=.3;:delay .3s;:beep frequency=2500 length=.3;:delay .3s;:beep frequency=2400 length=1;"];
$doStartBeep
:log info "BEGIN IMPORT file=$targetFile"
import $targetFile
:log info "END IMPORT file=$targetFile"
:delay 10s
$doFinishBeep
}
