$LetterTimeout = 300
$WordTimeout = 400
$MorseText = $InputText = ""
$ShowLetter = $DisableInput = $False
$MorseDuration = 100, 300, 700
$Mode = $AccentMode = 0
Set-Alias "new" "New-Object"
Set-Alias "regob" "Register-ObjectEvent"
$MorseToLetter = @{
	<# Letters, 1-4 characters #> A = ".-"; B = "-..."; C = "-.-."; D = "-.."; E = "."; F = "..-."; G = "--."; H = "...."; I = ".."; J = ".---"; K = "-.-"; L = ".-.."; M = "--"; N = "-."; O = "---"; P = ".--."; Q = "--.-"; R = ".-."; S = "..."; T = "-"; U = "..-"; V = "...-"; W = ".--"; X = "-..-"; Y = "-.--"; Z = "--.."
	<# Numbers, 5 characters #> "0" = "-----"; "1" = ".----"; "2" = "..---"; "3" = "...--"; "4" = "....-"; "5" = "....."; "6" = "-...."; "7" = "--..."; "8" = "---.."; "9" = "----."
	<# Symbols, 4-5 chracters #> "&" = ".-..."; "'" = ".----."; "@" = ".--.-."; "(" = "-.--."; ")" = "-.--.-"; ":" = "---..."; "," = "--..--"; "=" = "-...-"; "!" = "-.-.--"; "." = ".-.-.-"; "-" = "-....-"; "+" = ".-.-."; '"' = ".-..-."; "?" = "..--.."; "/" = "-..-."
	<# Prosign #> SOS = "...---..."; "`n" = ".-.-"
}
Function GetEntireBufferContents {Return ,$Host.UI.RawUI.GetBufferContents((new System.Management.Automation.Host.Rectangle (0, 0, ([Console]::WindowWidth - 1), ([Console]::WindowHeight - 1))))}
Function SetBGFG ($BGCol, $FGCol) {
	# If ($FGCol) {[Console]::ForegroundColor = $FGCol}
	# If ($BGCol) {[Console]::BackgroundColor = $BGCol}
	# $EntireScreen = GetEntireBufferContents
	# ForEach ($r In 0..($EntireScreen.GetLength(0) - 1)) {ForEach ($c In 0..($EntireScreen.GetLength(1) - 1)) {
		# If ($BGCol) {$EntireScreen[$r,$c] = new System.Management.Automation.Host.BufferCell (
			# $EntireScreen[$r,$c].Character,
			# $(If ($FGCol) {$FGCol} Else {$EntireScreen[$r,$c].ForegroundColor}),
			# $(If ($BGCol) {$BGCol} Else {$EntireScreen[$r,$c].BackgroundColor}),
			# $EntireScreen[$r,$c].BufferCellType
		# )}
	# }}
	# $Host.UI.RawUI.SetBufferContents(
		# (new System.Management.Automation.Host.Coordinates(0, 0)),
		# $EntireScreen
	# )
	[Console]::BackgroundColor = $BGCol
	[Console]::Clear()
}
Function ToLetter ($MorseText) {Return [String]($MorseToLetter.Keys | ? {$MorseToLetter[$_] -eq $MorseText})}
Function ReloadInputScreen {
	Clear-Host
	Write-Host "[R] Translation mode: " -NoNewLine
	$False, $True | % {
		If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
		$(Switch ($_) {$False{"Morse -> Text"} $True{"Text -> Morse"}}) | Write-Host -NoNewLine -Fore $(If ($False -eq $_) {"Yellow"} Else {"DarkGray"})
	}; Write-Host
	
	Write-Host $MorseText -NoNewLine
	If ($ShowLetter -and $MorseText) {Write-Host (" ({0}) " -f (ToLetter $MorseText)) -NoNewLine}
	Write-Host
	
	If (!$DisableInput) {Write-Host $InputText -Back "DarkBlue"} Else {Write-Host}
	
	Write-Host "[T] Show morse letter while typing: " -NoNewLine
	$False, $True | % {
		If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
		$(Switch ($_) {$False{"OFF"} $True{"ON"}}) | Write-Host -NoNewLine -Fore $(If ($ShowLetter -eq $_) {"Yellow"} Else {"DarkGray"})
	}; Write-Host
	
	Write-Host "[M] Typing mode: " -NoNewLine
	0..1 | % {
		If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
		$(Switch ($_) {0{"Morse to text, 2 keys"} 1{"Morse to text, 1 key"}}) | Write-Host -NoNewLine -Fore $(If ($Mode -eq $_) {"Yellow"} Else {"DarkGray"})
	}; Write-Host
	
	Write-Host "[A] Homophones: " -NoNewLine
	0..1 | % {
		If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
		$(Switch ($_) {0{"Use prosigns"} 1{"Use accented letters"}}) | Write-Host -NoNewLine -Fore $(If ($AccentMode -eq $_) {"Yellow"} Else {"DarkGray"})
	}; Write-Host
	
	Write-Host "[S] " -NoNewLine
	$False, $True | % {
		If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
		$(Switch ($_) {$False{"Sound and input"} $True{"Sound only"}}) | Write-Host -NoNewLine -Fore $(If ($DisableInput -eq $_) {"Yellow"} Else {"DarkGray"})
	}; Write-Host
}
$Media = new System.Media.SoundPlayer(".\morse.wav")
$StopSoundTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = 500}
$WordTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $WordTimeout}
$LetterTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $LetterTimeout}
$Morse1KeyStopwatch = new System.Diagnostics.Stopwatch
$TrUnitTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[0]}
$TrLetterTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[1]}
$TrWordTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[2]}
regob $StopSoundTimer "Elapsed" -Action {$Media.Stop(); If (!$DisableInput) {RestartTimer $LetterTimeoutTimer}} | Out-Null
regob $WordTimeoutTimer "Elapsed" -Action {.$InputAdd " "; ReloadInputScreen} | Out-Null
regob $LetterTimeoutTimer "Elapsed" -Action {
	.$InputAdd (ToLetter $MorseText)
	.$ClearMorse
	ReloadInputScreen
	RestartTimer $WordTimeoutTimer
} | Out-Null
regob $TrLetterTimeoutTimer "Elapsed" -Source "TrLetterTimeoutTimer"
regob $TrUnitTimeoutTimer "Elapsed" -Source "TrUnitTimeoutTimer"
regob $TrWordTimeoutTimer "Elapsed" -Source "TrWordTimeoutTimer"

$Dit = {If (!$DisableInput) {CancelTimeout; $MorseText += "."; ReloadInputScreen}; If ($Mode -eq 0) {$Media.PlayLooping(); $StopSoundTimer.Interval = 100; RestartTimer $StopSoundTimer}}
$Dah = {If (!$DisableInput) {CancelTimeout; $MorseText += "-"; ReloadInputScreen}; If ($Mode -eq 0) {$Media.PlayLooping(); $StopSoundTimer.Interval = 300; RestartTimer $StopSoundTimer}}
Function RestartTimer($TimerObj) {$TimerObj.Stop(); $TimerObj.Start()}
Function CancelTimeout() {If (!$DisableInput) {$LetterTimeoutTimer.Stop(); $WordTimeoutTimer.Stop()}}
#Register-EngineEvent "dit" -Action {[Console]::Beep(535,100)}
#Register-EngineEvent "dah" -Action {[Console]::Beep(535,300)}
ReloadInputScreen
$InputAdd = {Param ($String); $InputText += $String}
$ClearMorse = {$MorseText = ""}
Function TextToMorse {:TranslateLoop While ($True) {
	$Morse = ""
	cls
	Write-Host "[R] Translation mode: " -NoNewLine
	$False, $True | % {
		If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
		$(Switch ($_) {$False{"Morse -> Text"} $True{"Text -> Morse"}}) | Write-Host -NoNewLine -Fore $(If ($True -eq $_) {"Yellow"} Else {"DarkGray"})
	}; Write-Host
	
	Write-Host "Input text: " -NoNewLine
	
	($Raw = Read-Host).ToCharArray() | % {$Start = $True} {
		If (!$Start) {$Morse += " "}
		$Start = $False
		$Morse += $(If ($MorseToLetter[([String]$_).ToUpper()]) {$MorseToLetter[([String]$_).ToUpper()]} ElseIf ($_ -eq " ") {"/"} Else {"?"})
	}
	While ($True) {
		cls
		Write-Host "[R] Translation mode: " -NoNewLine
		$False, $True | % {
			If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
			$(Switch ($_) {$False{"Morse -> Text"} $True{"Text -> Morse"}}) | Write-Host -NoNewLine -Fore $(If ($True -eq $_) {"Yellow"} Else {"DarkGray"})
		}; Write-Host
		
		Write-Host "Input text: $Raw"
		
		Write-Host "Morse code:"
		Write-Host "$Morse"
		Write-Host "[P]: Play morse"
		Write-Host "[Backspace]: Another message"
		Switch ([Console]::ReadKey($True).KeyChar) {
			"p" {
				For ($i = 0; $i -lt $Morse.Length; $i++) {
					$Character = $Morse[$i]
					cls
					Write-Host "[R] Translation mode: " -NoNewLine
					$False, $True | % {
						If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
						$(Switch ($_) {$False{"Morse -> Text"} $True{"Text -> Morse"}}) | Write-Host -NoNewLine -Fore $(If ($True -eq $_) {"Yellow"} Else {"DarkGray"})
					}; Write-Host
					
					Write-Host "Input text: $Raw"
					
					Write-Host "Morse code:"
					$OldCur = [Console]::CursorLeft, [Console]::CursorTop
					Write-Host "$Morse"
					Write-Host "[P]: Play morse"
					Write-Host "[Backspace]: Another message"
					[Console]::SetCursorPosition($OldCur[0], $OldCur[1])
					Write-Host $Morse.Substring(0, $i) -NoNewLine
					Try {If ($Morse.Substring($i, 3) -eq " / ") {Write-Host " / " -Back "DarkYellow" -NoNewLine} Else {Throw}}
					Catch {If ($Morse -eq "?") {Write-Host $Character -Back "DarkRed" -NoNewLine} Else {Write-Host $Character -Back "DarkYellow" -NoNewLine}}
					If ($MorseSkip) {$MorseSkip--; Continue}
					Switch ($Character) {
						"." {$Media.PlayLooping(); RestartTimer $TrUnitTimeoutTimer; Wait-Event "TrUnitTimeoutTimer" | Remove-Event; $Media.Stop()}
						"-" {$Media.PlayLooping(); RestartTimer $TrLetterTimeoutTimer; Wait-Event "TrLetterTimeoutTimer" | Remove-Event; $Media.Stop()}
						" " {
							Try {If ($Morse.Substring($i, 3) -eq " / ") {$MorseSkip = 2; RestartTimer $TrWordTimeoutTimer; Wait-Event "TrWordTimeoutTimer" | Remove-Event} Else {Throw}}
							Catch {RestartTimer $TrLetterTimeoutTimer; Wait-Event "TrLetterTimeoutTimer" | Remove-Event}
						}
						"?" {0..7 | %{$Media.PlayLooping(); RestartTimer $TrUnitTimeoutTimer; Wait-Event "TrUnitTimeoutTimer" | Remove-Event; $Media.Stop()}}
					}
				}
			}
			"r" {Return}
			"`b" {Continue TranslateLoop}
		}
	}
}}
Try {[Console]::BufferWidth = 80} Catch {}
[Console]::BufferWidth = [Console]::WindowWidth = 80
Try {[Console]::BufferHeight = 25} Catch {}
[Console]::BufferHeight = [Console]::WindowHeight = 25
:MorseLoop While ($True) {
If ([Console]::KeyAvailable) {
	Switch ($Mode) {
		0 {Switch ([Console]::ReadKey($True).KeyChar) {
			"." {CancelTimeout; .$Dit}
			"-" {CancelTimeout; .$Dah}
			"0" {CancelTimeout; .$Dit}
			"1" {CancelTimeout; .$Dah}
			"t" {$ShowLetter = !$ShowLetter; ReloadInputScreen}
			"s" {$DisableInput = !$DisableInput; ReloadInputScreen}
			"a" {If (++$AccentMode -gt 1) {$AccentMode = 0}; ReloadInputScreen}
			"m" {If (++$Mode -gt 1) {$Mode = 0}; ReloadInputScreen}
			"r" {TextToMorse; ReloadInputScreen}
			"`b" {If (!$DisableInput) {
				CancelTimeout
				If ($MorseText) {$MorseText = ""}
				ElseIf ($InputText) {$InputText = $InputText.Remove($InputText.Length - 1)}
				ReloadInputScreen
			}}
			" " {If (!$DisableInput) {CancelTimeout; $MorseText = ""; $InputText += " "; ReloadInputScreen}}
		}}
		1 {
			Switch ($Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").Character) {
				"t" {$ShowLetter = !$ShowLetter; ReloadInputScreen; Continue MorseLoop}
				"s" {$DisableInput = !$DisableInput; ReloadInputScreen; Continue MorseLoop}
				"a" {If (++$AccentMode -gt 1) {$AccentMode = 0}; ReloadInputScreen}
				"m" {If (++$Mode -gt 1) {$Mode = 0}; ReloadInputScreen; Continue MorseLoop}
				"r" {TextToMorse; ReloadInputScreen; Continue MorseLoop}
				"`b" {If (!$DisableInput) {
					CancelTimeout
					If ($MorseText) {$MorseText = ""}
					ElseIf ($InputText) {$InputText = $InputText.Remove($InputText.Length - 1)}
					ReloadInputScreen
				}; Continue MorseLoop}
				" " {If (!$DisableInput) {CancelTimeout; $MorseText = ""; $InputText += " "; ReloadInputScreen}; Continue MorseLoop}
			}
			CancelTimeout
			$Media.PlayLooping()
			$Morse1KeyStopwatch.Start()
			$Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp") | Out-Null
			$Media.Stop()
			$Morse1KeyStopwatch.Stop()
			# 0     100    200    300    400
			#        .      [      -
			Switch ($Morse1KeyStopwatch.ElapsedMilliseconds -ge 200) {$False {.$Dit}; $True {.$Dah}}
			$Morse1KeyStopwatch.Reset()
			If (!$DisableInput) {RestartTimer $LetterTimeoutTimer}
		}
	}
}}