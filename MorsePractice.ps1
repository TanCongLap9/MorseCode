$LetterTimeout = 300
$WordTimeout = 400
$MorseText = $InputText = ""
$ShowLetter = $DisableInput = $ReturnMorseInput = $False
$MorseDuration = 100, 300, 700
$Mode = $AccentMode = $AutoReturn = 0
Set-Alias "new" "New-Object"
Set-Alias "regob" "Register-ObjectEvent"
$MorseToLetter = @{
	<# Letters, 1-4 characters #> A = ".-"; B = "-..."; C = "-.-."; D = "-.."; E = "."; F = "..-."; G = "--."; H = "...."; I = ".."; J = ".---"; K = "-.-"; L = ".-.."; M = "--"; N = "-."; O = "---"; P = ".--."; Q = "--.-"; R = ".-."; S = "..."; T = "-"; U = "..-"; V = "...-"; W = ".--"; X = "-..-"; Y = "-.--"; Z = "--.."
	<# Numbers, 5 characters #> "0" = "-----"; "1" = ".----"; "2" = "..---"; "3" = "...--"; "4" = "....-"; "5" = "....."; "6" = "-...."; "7" = "--..."; "8" = "---.."; "9" = "----."
	<# Symbols, 4-5 chracters #> "&" = ".-..."; "'" = ".----."; "@" = ".--.-."; "(" = "-.--."; ")" = "-.--.-"; ":" = "---..."; "," = "--..--"; "=" = "-...-"; "!" = "-.-.--"; "." = ".-.-.-"; "-" = "-....-"; "+" = ".-.-."; '"' = ".-..-."; "?" = "..--.."; "/" = "-..-."
	
	
	
	"*" = "...-."
	"[" = ".--.."
	"{" = ".--.-"
	"\" = "-.-.-"
	"<" = "-.---"
	'#' = "--.-."
	"%" = "---.-"
	"^" = "......"
	"$" = "...-.."
	"_" = "..--.-"
	"]" = ".--..-"
	"}" = ".--.--"
	'~' = ".---.."
	"``" = "-..-.-"
	';' = "-.-.-."
	'>' = "-.----"
	'|' = "--.-.-"

	
	
	<# Prosign #> SOS = "...---..."; "`n" = ".-.-"
}
<#
...-. *
.-... &
.-.-. +
.--.. [
.--.- {
-.-.- \
-.--- <
--.-. #
---.- %
...... ^
...-.. $
..--.. ?
..--.- _
.-..-. "
.-.-.- .
.--..- ]
.--.-. @
.--.-- }
.---.. ~
.----. '
-....- -
-..-.- `
-.-.-. ;
-.-.-- !
-.---- >
--..-- ,
--.-.- |
---... :
#>



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
$MorseGameStopwatch = new System.Diagnostics.Stopwatch
$TrUnitTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[0]}
$TrLetterTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[1]}
$TrWordTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[2]}
regob $StopSoundTimer "Elapsed" -Action {$Media.Stop(); If (!$DisableInput) {RestartTimer $LetterTimeoutTimer}} | Out-Null
regob $WordTimeoutTimer "Elapsed" -Action {If ($AutoReturn -eq 2) {.$ReturnMorseInputF; Return}; .$InputAdd " "; ReloadInputScreen} | Out-Null
regob $LetterTimeoutTimer "Elapsed" -Action {
	If ($AutoReturn -eq 1) {.$ReturnMorseInputF; Return}
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
$InputAdd = {Param ($String); $InputText += $String}
$ClearMorse = {$MorseText = ""}
$ReturnMorseInputF = {$ReturnMorseInput = $True}
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

Function MorseInput($Inp) {
If ($Inp) {$InputText = $Inp}
cls
ReloadInputScreen
:MorseLoop While ($True) {
If ([Console]::KeyAvailable) {Switch ($Mode) {
	0 {Switch ([Console]::ReadKey($True).KeyChar) {
		"." {CancelTimeout; .$Dit}
		"-" {CancelTimeout; .$Dah}
		"0" {CancelTimeout; .$Dit}
		"1" {CancelTimeout; .$Dah}
		"t" {$ShowLetter = !$ShowLetter; ReloadInputScreen}
		"s" {$DisableInput = !$DisableInput; ReloadInputScreen}
		"a" {If (++$AccentMode -gt 1) {$AccentMode = 0}; ReloadInputScreen}
		"m" {If (++$Mode -gt 1) {$Mode = 0}; ReloadInputScreen}
		" " {If (!$DisableInput) {CancelTimeout; $MorseText = ""; $InputText += " "; ReloadInputScreen}}
	}}
	1 {
		Switch ($Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").Character) {
			"t" {$ShowLetter = !$ShowLetter; ReloadInputScreen; Continue MorseLoop}
			"s" {$DisableInput = !$DisableInput; ReloadInputScreen; Continue MorseLoop}
			"a" {If (++$AccentMode -gt 1) {$AccentMode = 0}; ReloadInputScreen}
			"m" {If (++$Mode -gt 1) {$Mode = 0}; ReloadInputScreen; Continue MorseLoop}
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
}}; If ($ReturnMorseInput) {Break MorseLoop}}; cls; Return $MorseText}

Function PlayMorse ([Char[]]$MorseText) {
	Switch ($MorseText) {
		"." {$Media.PlayLooping(); RestartTimer $TrUnitTimeoutTimer; Wait-Event "TrUnitTimeoutTimer" | Remove-Event; $Media.Stop()}
		"-" {$Media.PlayLooping(); RestartTimer $TrLetterTimeoutTimer; Wait-Event "TrLetterTimeoutTimer" | Remove-Event; $Media.Stop()}
		" " {
			Try {If ($Morse.Substring($i, 3) -eq " / ") {RestartTimer $TrWordTimeoutTimer; Wait-Event "TrWordTimeoutTimer" | Remove-Event} Else {Throw}}
			Catch {RestartTimer $TrLetterTimeoutTimer; Wait-Event "TrLetterTimeoutTimer" | Remove-Event}
		}
		"?" {0..7 | %{$Media.PlayLooping(); RestartTimer $TrUnitTimeoutTimer; Wait-Event "TrUnitTimeoutTimer" | Remove-Event; $Media.Stop()}}
	}
}

While ($True) {
	cls
	Write-Host "[1]: Morse alphabet"
	Write-Host "[2]: Morse numbers"
	Write-Host "[3]: Morse symbols"
	Write-Host "[4]: Guess a character"
	Write-Host "[5]: Guess a word"
	Write-Host "[6]: Guess a phrase/sentence"
	:MenuLoop Switch ([Console]::ReadKey($True).KeyChar) {
		"1" {
			$Selection = 0
			$Mode = 0
			While ($True) {
				cls
				Write-Host "[Esc]: Return to menu"
				Write-Host "[Space/Enter]: Play morse"
				Write-Host "[M] " -NoNewLine
				0..2 | % {
					If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
					$(Switch ($_) {0{"Ascending alphabet"} 1{"Ascending morse"} 2{"Commonly mistaken morse"}}) | Write-Host -NoNewLine -Fore $(If ($Mode -eq $_) {"Yellow"} Else {"DarkGray"})
				}; Write-Host
				
				[Char[]]($MorseTable = $(Switch ($Mode) {0{-Join [Char[]]([Char]"A"..[Char]"Z")} 1{"ETIANMSURWDKGOHVFLPJBXCYZQ"} 2{"ABDCYQZEIFLGOKMNRWJPXTSUHV"}})) | % {$_.ToString()} | % {$i = 0} {
					If ($i -eq 13) {[Console]::CursorTop -= 13}
					If ($i -ge 13) {[Console]::CursorLeft = 15}
					$WHParam = @{}
					If ($Selection -eq $i) {$WHParam += @{"Back" = "DarkYellow"}}
					Write-Host "$_`: $($MorseToLetter[$_])" @WHParam
					$i++
				}
				Switch ([Console]::ReadKey($True).Key) {
					"UpArrow" {If ($Selection) {$Selection--} Else {$Selection = 25}}
					"DownArrow" {If ($Selection -lt 25) {$Selection++} Else {$Selection = 0}}
					{"LeftArrow", "RightArrow" -contains $_} {If ($Selection -lt 13) {$Selection += 13} Else {$Selection -= 13}}
					{"Enter", "Spacebar" -contains $_} {PlayMorse $MorseToLetter[$MorseTable[$Selection].ToString()]}
					"Escape" {Break MenuLoop}
					"M" {If (++$Mode -gt 2) {$Mode = 0}}
				}
			}
		}
		"2" {
			$Selection = 0
			While ($True) {
				cls
				Write-Host "[Esc]: Return to menu"
				Write-Host "[Space/Enter]: Play morse"
				
				[Char[]]($MorseTable = "0123456789") | % {$_.ToString()} | % {$i = 0} {
					If ($i -eq 5) {[Console]::CursorTop -= 5}
					If ($i -ge 5) {[Console]::CursorLeft = 15}
					$WHParam = @{}
					If ($Selection -eq $i) {$WHParam += @{"Back" = "DarkYellow"}}
					Write-Host "$_`: $($MorseToLetter[$_])" @WHParam
					$i++
				}
				Switch ([Console]::ReadKey($True).Key) {
					"UpArrow" {If ($Selection) {$Selection--} Else {$Selection = 9}}
					"DownArrow" {If ($Selection -lt 9) {$Selection++} Else {$Selection = 0}}
					{"LeftArrow", "RightArrow" -contains $_} {If ($Selection -lt 5) {$Selection += 5} Else {$Selection -= 5}}
					{"Enter", "Spacebar" -contains $_} {PlayMorse $MorseToLetter[$MorseTable[$Selection].ToString()]}
					"Escape" {Break MenuLoop}
					"M" {If (++$Mode -gt 2) {$Mode = 0}}
				}
			}
		}
		"3" {
			$Selection = 0
			$Mode = 0
			While ($True) {
				cls
				Write-Host "[Esc]: Return to menu"
				Write-Host "[Space/Enter]: Play morse"
				Write-Host "[M] " -NoNewLine
				0..2 | % {
					If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
					$(Switch ($_) {0{"Ascending alphabet"} 1{"Ascending morse"} 2{"Commonly mistaken morse"}}) | Write-Host -NoNewLine -Fore $(If ($Mode -eq $_) {"Yellow"} Else {"DarkGray"})
				}; Write-Host
				
				[Char[]]($MorseTable = $(Switch ($Mode) {0{-Join [Char[]]([Char]"A"..[Char]"Z")} 1{"ETIANMSURWDKGOHVFLPJBXCYZQ"} 2{"ABDCYQZEIFLGOHKMNJPXRSTUVW"}})) | % {$_.ToString()} | % {$i = 0} {
					If ($i -eq 13) {[Console]::CursorTop -= 13}
					If ($i -ge 13) {[Console]::CursorLeft = 15}
					$WHParam = @{}
					If ($Selection -eq $i) {$WHParam += @{"Back" = "DarkYellow"}}
					Write-Host "$_`: $($MorseToLetter[$_])" @WHParam
					$i++
				}
				Switch ([Console]::ReadKey($True).Key) {
					"UpArrow" {If ($Selection) {$Selection--} Else {$Selection = 25}}
					"DownArrow" {If ($Selection -lt 25) {$Selection++} Else {$Selection = 0}}
					{"LeftArrow", "RightArrow" -contains $_} {If ($Selection -lt 13) {$Selection += 13} Else {$Selection -= 13}}
					{"Enter", "Spacebar" -contains $_} {PlayMorse $MorseToLetter[$MorseTable[$Selection].ToString()]}
					"Escape" {Break MenuLoop}
					"M" {If (++$Mode -gt 2) {$Mode = 0}}
				}
			}
		}
		"4" {
			$Flag = 0
			$Range = ""
			:Option While ($True) {
				cls
				Write-Host "[" -NoNewLine; Write-Host 1 -Fore $(If ($Flag -bAnd 1) {"Yellow"} Else {"Gray"}) -NoNewLine; Write-Host "]: Enable letters"
				Write-Host "[" -NoNewLine; Write-Host 2 -Fore $(If ($Flag -bAnd 2) {"Yellow"} Else {"Gray"}) -NoNewLine; Write-Host "]: Enable numbers"
				Write-Host "[" -NoNewLine; Write-Host 3 -Fore $(If ($Flag -bAnd 4) {"Yellow"} Else {"Gray"}) -NoNewLine; Write-Host "]: Enable symbols"
				Write-Host "[4] Mode: " -NoNewLine
				$False, $True | % {
					If ($_) {Write-Host " | " -Fore "DarkGray" -NoNewLine}
					$(Switch ($_) {$False{"Type a morse character"} $True{"Listen to morse"}}) | Write-Host -NoNewLine -Fore $(If ($_ -eq ($Flag -bAnd 8)) {"Yellow"} Else {"DarkGray"})
				}; Write-Host
				
				Write-Host "[Enter]: Start!"
				Switch ([Console]::ReadKey($True).KeyChar) {
					"1" {$Flag = $Flag -bXor 1}
					"2" {$Flag = $Flag -bXor 2}
					"3" {$Flag = $Flag -bXor 4}
					"4" {$Flag = $Flag -bXor 8}
					"`r" {If ($Flag -bAnd 7) {Break Option}}
				}
			}
			If ($Flag -bAnd 1) {$Range += -Join [Char[]]([Char]"A"..[Char]"Z")}
			If ($Flag -bAnd 2) {$Range += -Join [Char[]]([Char]"0"..[Char]"9")}
			If ($Flag -bAnd 4) {$Range += ""}
			If ($Flag -bAnd 8) {
				:GameLoop1 While ($True) {
					cls
					$RandomChar = $Range[(Random -Min 0 -Max $Range.Length)].ToString()
					$Count = 0
					Write-Host "[Enter]: Play"
					$MorseGameStopwatch.Start()
					:InpLoop While ($True) {Switch ([Console]::ReadKey($True)) {
						{$_.KeyChar -eq "`r"} {$Count++; PlayMorse $MorseToLetter[$RandomChar]}
						{0x20..0x7e -contains $_.KeyChar} {$Character = $_.KeyChar.ToString().ToUpper(); Break InpLoop}
					}}
					$MorseGameStopwatch.Stop()
					Write-Host $(If ($Character -eq $RandomChar) {[Char]0x221a} Else {[Char]0x00d7}) -Fore $(If ($Character -eq $RandomChar) {"Green"} Else {"Red"})
					Write-Host "Input: $Character"
					Write-Host $(If ($Character -ne $RandomChar) {"Correct: " + $RandomChar})
					Write-Host ("{0:f2} seconds" -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
					Write-Host $(Switch ($Count) {2{"Listened twice"} 1{"Listened once"} 0{'Literally "guessed" without listening'} Default{"Repeated $Count times"}}) -Fore $(Switch ($Count) {1{"Green"} 0{"Red"} Default{"Yellow"}})
					Write-Host
					Write-Host "[Escape]: Return to menu"
					Write-Host "[R/Enter]: Retry"
					$MorseGameStopwatch.Reset()
					#$Host.UI.RawUI.SetBufferContents((new System.Management.Automation.Host.Coordinates(0, 0)), $OldScreenPos[0])
					#$Host.UI.RawUI.CursorPosition = $OldScreenPos[1]
					While ($True) {Switch ([Console]::ReadKey($True).KeyChar) {
						{"`r", "r" -contains $_} {Continue GameLoop1}
						([Char]0x1b) {Break GameLoop1}
					}}
				}
			}
			Else {
				$AutoReturn = 1
				:GameLoop1 While ($True) {
					$RandomChar = $Range[(Random -Min 0 -Max $Range.Length)].ToString()
					$MorseGameStopwatch.Start()
					#$OldScreenPos = (GetEntireBufferContents), $Host.UI.RawUI.CursorPosition
					$Morse = MorseInput $RandomChar
					$MorseGameStopwatch.Stop()
					Write-Host $(If ($Morse -eq $MorseToLetter[$RandomChar]) {[Char]0x221a} Else {[Char]0x00d7}) -Fore $(If ($Morse -eq $MorseToLetter[$RandomChar]) {"Green"} Else {"Red"})
					Write-Host "Input: $Morse"
					Write-Host $(If ($Morse -ne $MorseToLetter[$RandomChar]) {"Correct: " + $MorseToLetter[$RandomChar]})
					Write-Host ("{0:f2} seconds" -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
					Write-Host
					Write-Host "[Escape]: Return to menu"
					Write-Host "[R/Enter]: Retry"
					Write-Host "[P]: Play morse"
					$MorseGameStopwatch.Reset()
					#$Host.UI.RawUI.SetBufferContents((new System.Management.Automation.Host.Coordinates(0, 0)), $OldScreenPos[0])
					#$Host.UI.RawUI.CursorPosition = $OldScreenPos[1]
					While ($True) {Switch ([Console]::ReadKey($True).KeyChar) {
						{"`r", "r" -contains $_} {Continue GameLoop1}
						"p" {PlayMorse $MorseToLetter[$RandomChar]}
						([Char]0x1b) {Break GameLoop1}
					}}
				}
			}
		}
		"5" {
			$Dict = "ate", "eat", "tea", "ten", "net", "teen", "meet", "met", "it", "at", "man", "woman", "morse", "code", "hello", "hi", "hey", "bye", "goodbye", "i", "you", "he", "she", "they", "my", "your", "his", "her", "their", "me", "him", "them", "love", "hate", "what", "where", "when", "why", "who", "how", "the", "quick", "slow", "fox", "foxy", "dog", "dodge", "slow", "quirk", "jump", "message", "massage", "international", "internationalize", "internationalization", "signal", "hear", "receive", "transmit"
			
		}
		"6" {
			$Dict = "I love you.", "Hello.", "Hi.", "The quick brown fox jumps over the lazy dog.", "Morse code", "There are 26 letters, and 10 digits in morse code.", "International morse code", "Help me!", "Thank you!", "Thanks.", "Thanks a lot!", "Thanks a bunch!", "Thank you very much!", "Thank you so much!", "How are you?", "See you later.", "See you.", "See ya.", "Goodbye.", "Bye.", "Where are you?"
		}
	}
}