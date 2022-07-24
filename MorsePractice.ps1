#Requires -Version 2.0
$MorseText = ""
$ReturnMorseInput = $False
$MorseDuration = 100, 300, 700, 100, 300, 400
$TypingMode = $AutoReturn = 0
Set-Alias "new" "New-Object"
Set-Alias "regob" "Register-ObjectEvent"
$MorseToLetter = @{
	<# Letters, 1-4 characters #> A = ".-"; B = "-..."; C = "-.-."; D = "-.."; E = "."; F = "..-."; G = "--."; H = "...."; I = ".."; J = ".---"; K = "-.-"; L = ".-.."; M = "--"; N = "-."; O = "---"; P = ".--."; Q = "--.-"; R = ".-."; S = "..."; T = "-"; U = "..-"; V = "...-"; W = ".--"; X = "-..-"; Y = "-.--"; Z = "--.."
	<# Numbers, 5 characters #> "0" = "-----"; "1" = ".----"; "2" = "..---"; "3" = "...--"; "4" = "....-"; "5" = "....."; "6" = "-...."; "7" = "--..."; "8" = "---.."; "9" = "----."
	<# Symbols, 4-5 chracters #> "&" = ".-..."; "'" = ".----."; "@" = ".--.-."; "(" = "-.--."; ")" = "-.--.-"; ":" = "---..."; "," = "--..--"; "=" = "-...-"; "!" = "-.-.--"; "." = ".-.-.-"; "-" = "-....-"; "+" = ".-.-."; '"' = ".-..-."; "?" = "..--.."; "/" = "-..-."; "*" = "...-."; "[" = ".--.."; "{" = ".--.-"; "\" = "-.-.-"; "<" = "-.---"; '#' = "--.-."; "%" = "---.-"; "^" = "......"; "$" = "...-.."; "_" = "..--.-"; "]" = ".--..-"; "}" = ".--.--"; '~' = ".---.."; "``" = "-..-.-"; ';' = "-.-.-."; '>' = "-.----"; '|' = "--.-.-"
	<# Prosign #> SOS = "...---..."; "`n" = ".-.-"; Error = "........"
}
Function Write-Selection ([String]$Text, [Object[][]]$ValueTexts, $CurrentValue) {
	If ($Text) {Write-Host $Text -No}
	$ValueTexts | % {$i = 0} {
		If ($i++) {Write-Host " | " -Fore "DarkGray" -No}
		Write-Host $_[1] -No -Fore $(If ($CurrentValue.Equals($_[0])) {"Yellow"} Else {"DarkGray"})
	}; Write-Host
}
Function GetEntireBufferContents {Return ,$Host.UI.RawUI.GetBufferContents((new System.Management.Automation.Host.Rectangle (0, 0, ([Console]::WindowWidth - 1), ([Console]::WindowHeight - 1))))}
Function SetBGFG ($BGCol, $FGCol) {
	<# If ($FGCol) {[Console]::ForegroundColor = $FGCol}
	If ($BGCol) {[Console]::BackgroundColor = $BGCol}
	$EntireScreen = GetEntireBufferContents
	ForEach ($r In 0..($EntireScreen.GetLength(0) - 1)) {ForEach ($c In 0..($EntireScreen.GetLength(1) - 1)) {
		If ($BGCol) {$EntireScreen[$r,$c] = new System.Management.Automation.Host.BufferCell (
			$EntireScreen[$r,$c].Character,
			$(If ($FGCol) {$FGCol} Else {$EntireScreen[$r,$c].ForegroundColor}),
			$(If ($BGCol) {$BGCol} Else {$EntireScreen[$r,$c].BackgroundColor}),
			$EntireScreen[$r,$c].BufferCellType
		)}
	}}
	$Host.UI.RawUI.SetBufferContents(
		(new System.Management.Automation.Host.Coordinates(0, 0)),
		$EntireScreen
	) #>
	[Console]::BackgroundColor = $BGCol
	[Console]::Clear()
}
Function ToLetter ($MorseText) {Return [String]($MorseToLetter.Keys | ? {$MorseToLetter[$_] -eq $MorseText})}
Function ReloadInputScreen {
	Clear-Host
	Write-Host $MorseText -No -Back "DarkGreen"
	Write-Host
	Write-Host $InputText -Back "DarkBlue"
	Write-Selection "[M] Typing mode: " (0, "2 keys"), (1, "1 key") $TypingMode
}
$Media = new System.Media.SoundPlayer(".\morse.wav")
$TrTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[0]}
$StopSoundTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[0]}
$WordTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[5]}
$LetterTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[4]}
$Morse1KeyStopwatch = new System.Diagnostics.Stopwatch
$MorseGameStopwatch = new System.Diagnostics.Stopwatch
regob $StopSoundTimer "Elapsed" -Action {$Media.Stop(); RestartTimer ([Ref]$LetterTimeoutTimer)} | Out-Null
regob $WordTimeoutTimer "Elapsed" -Action {If ($AutoReturn -eq 2) {([Ref]$ReturnMorseInput).Value = $True; ([Ref]$MorseText).Value = $MorseText.Remove($MorseText.Length - 1); Return}; ([Ref]$MorseText).Value += "/ "; ReloadInputScreen} | Out-Null
regob $LetterTimeoutTimer "Elapsed" -Action {
	If ($AutoReturn -eq 1) {([Ref]$ReturnMorseInput).Value = $True; Return}
	If ($AutoReturn -eq 3) {If ($MorseText.Length -ge 4 -and $MorseText.Remove(0, $MorseText.Length - 4) -eq ".-.-") {([Ref]$ReturnMorseInput).Value = $True; Return}}
	([Ref]$MorseText).Value += " "
	ReloadInputScreen
	RestartTimer ([Ref]$WordTimeoutTimer)
} | Out-Null
regob $TrTimeoutTimer "Elapsed" -Source "TrTimeoutTimer"

$Dit = {CancelTimeout; ([Ref]$MorseText).Value += "."; ReloadInputScreen; If ($TypingMode -eq 0) {$Media.PlayLooping(); RestartTimer ([Ref]$StopSoundTimer) $MorseDuration[3]}}
$Dah = {CancelTimeout; ([Ref]$MorseText).Value += "-"; ReloadInputScreen; If ($TypingMode -eq 0) {$Media.PlayLooping(); RestartTimer ([Ref]$StopSoundTimer) $MorseDuration[4]}}
Function RestartTimer([Ref]$TimerObj, $Interval) {$TimerObj.Value.Stop(); If ($Interval -ne $Null) {$TimerObj.Value.Interval = $Interval}; $TimerObj.Value.Start()}
Function CancelTimeout() {$LetterTimeoutTimer.Stop(); $WordTimeoutTimer.Stop()}
#Register-EngineEvent "dit" -Action {[Console]::Beep(535,100)}
#Register-EngineEvent "dah" -Action {[Console]::Beep(535,300)}
Try {[Console]::BufferWidth = 80} Catch {}
[Console]::BufferWidth = [Console]::WindowWidth = 80
Try {[Console]::BufferHeight = 25} Catch {}
[Console]::BufferHeight = [Console]::WindowHeight = 25

Function MorseInput($Inp) {
([Ref]$MorseText).Value = ""
$InputText = If ($Inp) {$Inp} Else {""}
cls
ReloadInputScreen
:MorseLoop While ($True) {
If ([Console]::KeyAvailable) {Switch ($TypingMode) {
	0 {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.KeyChar) {
		{".", "0" -contains $_} {CancelTimeout; .$Dit}
		{"-", "1" -contains $_} {CancelTimeout; .$Dah}
		"m" {If (++(([Ref]$TypingMode).Value) -gt 1) {([Ref]$TypingMode).Value = 0}; ReloadInputScreen}
	}}}}
	1 {
		Switch ($Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").Character) {
			"m" {If (++(([Ref]$TypingMode).Value) -gt 1) {([Ref]$TypingMode).Value = 0}; ReloadInputScreen; Continue MorseLoop}
		}
		CancelTimeout
		$Media.PlayLooping()
		$Morse1KeyStopwatch.Start()
		$Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp") | Out-Null
		$Media.Stop()
		$Morse1KeyStopwatch.Stop()
		If ($Morse1KeyStopwatch.ElapsedMilliseconds -lt 200) {.$Dit} Else {.$Dah}
		$Morse1KeyStopwatch.Reset()
		RestartTimer ([Ref]$LetterTimeoutTimer)
	}
}}; If ($ReturnMorseInput) {([Ref]$ReturnMorseInput).Value = $False; Break MorseLoop}}; cls; Return $MorseText}
Function PlayMorse ([Char[]]$MorseText) {
	Switch ($MorseText) {
		"." {$Media.PlayLooping(); RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[0]; Wait-Event "TrTimeoutTimer" | Remove-Event; $Media.Stop()}
		"-" {$Media.PlayLooping(); RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[1]; Wait-Event "TrTimeoutTimer" | Remove-Event; $Media.Stop()}
		" " {
			Try {If ($Morse.Substring($i, 3) -eq " / ") {RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[2]; Wait-Event "TrTimeoutTimer" | Remove-Event} Else {Throw}}
			Catch {RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[1]; Wait-Event "TrTimeoutTimer" | Remove-Event}
		}
		"?" {0..7 | %{$Media.PlayLooping(); RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[0]; Wait-Event "TrTimeoutTimer" | Remove-Event; $Media.Stop()}}
	}
}
Function Learn {
	$Selection = $Mode = $LearnMode = 0
	While ($True) {
		cls
		Write-Host @"
[Esc]: Return to menu
[Space/Enter]: Play morse
"@
		Write-Selection "[T] Character type: " (0, "Letter"), (1, "Number"), (2, "Symbol"), (3, "Prosign") $LearnMode
		Switch ($LearnMode) {
			0 {
				$Modes = 3
				Write-Selection "[M] Sorting: " (0, "Ascending alphabet"), (1, "Ascending morse"), (2, "Commonly mistaken morse") $Mode
				[Char[]]$MorseTable = Switch ($Mode) {0{[Char[]]([Char]"A"..[Char]"Z")} 1{"ETIANMSURWDKGOHVFLPJBXCYZQ"} 2{"ABDCYQZEIFLGOKMNRWJPXTSUHV"}}
			}
			1 {
				$Modes = 1
				Write-Host
				[Char[]]$MorseTable = "0123456789"
			}
			2 {
				$Modes = 3
				Write-Selection "[M] Sorting: " (0, "Ascending symbol"), (1, "Ascending morse"), (2, "Commonly mistaken morse") $Mode
				[Char[]]$MorseTable = Switch ($Mode) {0{"`n" + '!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'} 1{"`n" + '*&+[{=/\(<#%^$?_".]@}~''-`;!)>,|:'} 2{"`n" + '\!;"+#|$%&''()*,-=./`:<>?_@[]^{}~'}}
			}
			3 {
				$Modes = 3
				Write-Host (@"
6111111111111111111111111111111111111111111111111111111111111111111111111113
2Prosign is much like abbreviation of morse code.                          2
2In this program, a few prosigns are supported.                            2
5111111111111111111111111111111111111111111111111111111111111111111111111114
"@ -Replace ("1", ([Char]0x2500)) -Replace ("2", ([Char]0x2502)) -Replace ("3", ([Char]0x2510)) -Replace ("4", ([Char]0x2518)) -Replace ("5", ([Char]0x2514)) -Replace ("6", ([Char]0x250c)))
				[Object[]]$MorseTable = "SOS", "`n", "Error"
			}
		}
		$MorseTable | % {$_.ToString()} | % {$i = 0} {
			If ($i -eq [Math]::Ceiling($MorseTable.Length / 2)) {[Console]::CursorTop -= [Math]::Ceiling($MorseTable.Length / 2)}
			If ($i -ge [Math]::Ceiling($MorseTable.Length / 2)) {[Console]::CursorLeft = 15}
			$WHParam = @{}
			If ($Selection -eq $i) {$WHParam += @{"Back" = "DarkYellow"}}
			Write-Host ("{0} $($MorseToLetter[$_])" -f ("$_" -Replace "`n", "[ENTER]")) @WHParam
			$i++
		}
		Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
			"UpArrow" {If ($Selection) {$Selection--} Else {$Selection = $MorseTable.Length - 1}}
			"DownArrow" {If ($Selection -lt $MorseTable.Length - 1) {$Selection++} Else {$Selection = 0}}
			{"LeftArrow", "RightArrow" -contains $_} {If ($Selection -lt [Math]::Floor($MorseTable.Length / 2)) {$Selection += [Math]::Ceiling($MorseTable.Length / 2)} Else {$Selection -= [Math]::Floor($MorseTable.Length / 2)}}
			{"Enter", "Spacebar" -contains $_} {PlayMorse $MorseToLetter[$MorseTable[$Selection].ToString()]}
			"Escape" {Break MenuLoop}
			"M" {If (++$Mode -ge $Modes) {$Mode = 0}}
			"T" {$Selection = $Mode = 0; If (++$LearnMode -ge 4) {$LearnMode = 0}}
		}}}
	}
}
Function GuessChar {
	$Flag = 0
	$Range = ""
	:Option While ($True) {
		cls
		Write-Host "[Esc]: Back to menu"
		Write-Host "[" -NoNewLine; Write-Host 1 -Fore $(If ($Flag -bAnd 1) {"Yellow"} Else {"DarkGray"}) -NoNewLine; Write-Host "]: Enable letters"
		Write-Host "[" -NoNewLine; Write-Host 2 -Fore $(If ($Flag -bAnd 2) {"Yellow"} Else {"DarkGray"}) -NoNewLine; Write-Host "]: Enable numbers"
		Write-Host "[" -NoNewLine; Write-Host 3 -Fore $(If ($Flag -bAnd 4) {"Yellow"} Else {"DarkGray"}) -NoNewLine; Write-Host "]: Enable symbols"
		Write-Selection "[M] Mode: " ($False, "Type in morse"), ($True, "Listen to morse") ([bool]($Flag -bAnd 8))
		
		Write-Host "[Enter]: Start!"
		Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_) {
			{"1" -eq $_.KeyChar} {$Flag = $Flag -bXor 1}
			{"2" -eq $_.KeyChar} {$Flag = $Flag -bXor 2}
			{"3" -eq $_.KeyChar} {$Flag = $Flag -bXor 4}
			{"M" -eq $_.Key} {$Flag = $Flag -bXor 8}
			{"Escape" -eq $_.Key} {Return}
			{"Enter" -eq $_.Key} {If ($Flag -bAnd 7) {Break Option}}
		}}}
	}
	If ($Flag -bAnd 1) {$Range += -Join [Char[]]([Char]"A"..[Char]"Z")}
	If ($Flag -bAnd 2) {$Range += -Join [Char[]]([Char]"0"..[Char]"9")}
	If ($Flag -bAnd 4) {$Range += "`n" + '!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'}
	If ($Flag -bAnd 8) {
		:GameLoop1 While ($True) {
			cls
			$RandomChar = $Range[(Random -Min 0 -Max $Range.Length)].ToString()
			$Count = 0
			Write-Host @"
[Enter]: Play
Type a character
"@
			$MorseGameStopwatch.Start()
			:InpLoop While ($True) {Switch ([Console]::ReadKey($True)) {
				{"Enter" -eq $_.Key} {$Count++; PlayMorse $MorseToLetter[$RandomChar]}
				{0x20..0x7e -contains $_.KeyChar} {$Character = $_.KeyChar.ToString().ToUpper(); Break InpLoop}
			}}
			$MorseGameStopwatch.Stop()
			Write-Host "Input: $Character"
			Write-Host $(If ($Character -eq $RandomChar) {"Correct"} Else {"Incorrect"}) -Fore $(If ($Character -eq $RandomChar) {"Green"} Else {"Red"})
			Write-Host $(If ($Character -ne $RandomChar) {"Correct: $RandomChar"})
			If (!$Count) {Write-Host 'Literally "guessed" without listening' -Fore "Red"} ElseIf ($Character -eq $RandomChar) {Write-Host $(Switch ($Count) {2{"Listened twice"} 1{"Listened once"} Default{"Listened $Count times"}}) -Fore $(Switch ($Count) {1{"Green"} Default{"Yellow"}})} Else {Write-Host}
			Write-Host (@"
{0:f2}s
[Escape]: Return to menu
[R/Enter]: Retry
[P]: Play morse
"@ -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
			$MorseGameStopwatch.Reset()
			While ($True) {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
				{"R", "Enter" -contains $_} {Continue GameLoop1}
				"P" {PlayMorse $MorseToLetter[$RandomChar]}
				"Escape" {Break GameLoop1}
			}}}}
		}
	}
	Else {
		([Ref]$AutoReturn).Value = 1
		:GameLoop1 While ($True) {
			$RandomChar = $Range[(Random -Min 0 -Max $Range.Length)].ToString()
			$MorseGameStopwatch.Start()
			#$OldScreenPos = (GetEntireBufferContents), $Host.UI.RawUI.CursorPosition
			$Morse = MorseInput $RandomChar
			$MorseGameStopwatch.Stop()
			Write-Host "Input: $Morse"
			Write-Host $(If ($Morse -eq $MorseToLetter[$RandomChar]) {"Correct"} Else {"Incorrect"}) -Fore $(If ($Morse -eq $MorseToLetter[$RandomChar]) {"Green"} Else {"Red"})
			Write-Host $(If ($Morse -ne $MorseToLetter[$RandomChar]) {"Correct: " + $MorseToLetter[$RandomChar]})
			Write-Host
			Write-Host (@"
{0:f2}s
[Escape]: Return to menu
[R/Enter]: Retry
[P]: Play morse
"@ -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
			$MorseGameStopwatch.Reset()
			While ($True) {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
				{"R", "Enter" -contains $_} {Continue GameLoop1}
				"P" {PlayMorse $MorseToLetter[$RandomChar]}
				"Escape" {Break GameLoop1}
			}}}}
		}
	}
}
Function GuessWord {
	$Flag = 0
	$WordInput = ""
	:Option While ($True) {
		cls
		Write-Host "[Esc]: Back to menu"
		Write-Selection "[M] Mode: " ($False, "Type in morse"), ($True, "Listen to morse") ([bool]$Flag)
		Write-Host "[Enter]: Start!"
		Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_) {
			{"M" -eq $_.Key} {$Flag = !$Flag}
			{"Enter" -eq $_.Key} {Break Option}
			{"Escape" -eq $_.Key} {Return}
		}}}
	}
	$Dict = "ate", "eat", "tea", "ten", "net", "teen", "meet", "met", "it", "at", "man", "woman", "morse", "code", "hello", "hi", "hey", "bye", "goodbye", "i", "you", "he", "she", "they", "my", "your", "his", "her", "their", "me", "him", "them", "love", "hate", "what", "where", "when", "why", "who", "how", "the", "quick", "slow", "fox", "foxy", "dog", "dodge", "slow", "quirk", "jump", "message", "massage", "international", "internationalize", "internationalization", "signal", "hear", "receive", "transmit", "transmission", "mission", "start", "begin", "end", "final"
	If ($Flag) {
		:GameLoop1 While ($True) {
			$RandomWord = Random $Dict
			$Count = 0
			:InpLoop While ($True) {
				cls
				Write-Host @"
[Space]: Play
Type a word, then press [Enter] to submit
"@
				Write-Host $WordInput -No
				$MorseGameStopwatch.Start()
				Switch ([Console]::ReadKey($True)) {
					{"Spacebar" -eq $_.Key} {$Count++; PlayMorse (([Char[]]$RandomWord | % {$MorseToLetter[$_.ToString()]}) -Join " ")}
					{"Enter" -eq $_.Key} {Break InpLoop}
					{"Backspace" -eq $_.Key} {If ($WordInput) {$WordInput = $WordInput.Remove($WordInput.Length - 1)}}
					{0x21..0x7e -contains $_.KeyChar} {$WordInput += $_.KeyChar.ToString().ToLower()}
				}
			}
			Write-Host
			$MorseGameStopwatch.Stop()
			Write-Host "Input: $WordInput"
			Write-Host $(If ($WordInput -eq $RandomWord) {"Correct"} Else {"Incorrect"}) -Fore $(If ($WordInput -eq $RandomWord) {"Green"} Else {"Red"})
			Write-Host $(If ($WordInput -ne $RandomWord) {"Correct: $RandomWord"})
			If (!$Count) {Write-Host 'Literally "guessed" without listening' -Fore "Red"} ElseIf ($WordInput -eq $RandomWord) {Write-Host $(Switch ($Count) {2{"Listened twice"} 1{"Listened once"} Default{"Listened $Count times"}}) -Fore $(Switch ($Count) {1{"Green"} Default{"Yellow"}})} Else {Write-Host}
			Write-Host (@"
{0:f2}s
[Escape]: Return to menu
[R/Enter]: Retry
[P]: Play morse
"@ -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
			$MorseGameStopwatch.Reset()
			While ($True) {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
				{"R", "Enter" -contains $_} {Continue GameLoop1}
				"P" {PlayMorse PlayMorse (([Char[]]$RandomWord | % {$MorseToLetter[$_.ToString()]}) -Join " ")}
				"Escape" {Return}
			}}}}
		}
	}
	Else {
		([Ref]$AutoReturn).Value = 2
		:GameLoop1 While ($True) {
			$RandomWord = Random $Dict
			$MorseGameStopwatch.Start()
			#$OldScreenPos = (GetEntireBufferContents), $Host.UI.RawUI.CursorPosition
			$Morse = MorseInput $RandomWord
			$RandomWordMorse = ([Char[]]$RandomWord | % {$MorseToLetter[$_.ToString()]}) -Join " "
			$MorseGameStopwatch.Stop()
			Write-Host "Input: $Morse"
			Write-Host $(If ($Morse -eq $RandomWordMorse) {"Correct"} Else {"Incorrect"}) -Fore $(If ($Morse -eq $RandomWordMorse) {"Green"} Else {"Red"})
			Write-Host $(If ($Morse -ne $RandomWordMorse) {"Correct: $RandomWordMorse"})
			Write-Host
			Write-Host (@"
{0:f2}s
[Escape]: Return to menu
[R/Enter]: Retry
[P]: Play morse
"@ -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
			$MorseGameStopwatch.Reset()
			While ($True) {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
				{"R", "Enter" -contains $_} {Continue GameLoop1}
				"P" {PlayMorse $RandomWordMorse}
				"Escape" {Return}
			}}}}
		}
	}
}
Function GuessPhrase {
	$Flag = 0
	$WordInput = ""
	:Option While ($True) {
		cls
		Write-Host "[Esc]: Back to menu"
		Write-Selection "[M] Mode: " ($False, "Type in morse"), ($True, "Listen to morse") ([bool]$Flag)
		Write-Host "[Enter]: Start!"
		Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_) {
			{"M" -eq $_.Key} {$Flag = !$Flag}
			{"Enter" -eq $_.Key} {Break Option}
			{"Escape" -eq $_.Key} {Return}
		}}}
	}
	$Dict = "I love you.", "Hello.", "Hi.", "The quick brown fox jumps over the lazy dog.", "Morse code", "There are 26 letters, and 10 digits in morse code.", "International morse code", "Help me!", "Thank you!", "Thanks.", "Thanks a lot!", "Thanks a bunch!", "Thank you very much!", "Thank you so much!", "How are you?", "See you later.", "See you.", "See ya.", "Goodbye.", "Bye.", "Where are you?", "Who are you?", "Message received.", "Message sent."
	If ($Flag) {
		:GameLoop1 While ($True) {
			$RandomWord = Random $Dict
			$Count = 0
			:InpLoop While ($True) {
				cls
				Write-Host @"
[Ctrl + P]: Play
Type a word, then press [Enter] to submit
"@
				Write-Host $WordInput -No
				$MorseGameStopwatch.Start()
				Switch ([Console]::ReadKey($True)) {
					{"P" -eq $_.Key -and "Ctrl" -eq $_.Modifiers} {$Count++; PlayMorse (([Char[]]$RandomWord | % {$MorseToLetter[$_.ToString()]}) -Join " ")}
					{"Enter" -eq $_.Key} {Break InpLoop}
					{"Backspace" -eq $_.Key} {If ($WordInput) {$WordInput = $WordInput.Remove($WordInput.Length - 1)}}
					{0x21..0x7e -contains $_.KeyChar} {$WordInput += $_.KeyChar.ToString().ToLower()}
				}
			}
			Write-Host
			$MorseGameStopwatch.Stop()
			Write-Host "Input: $WordInput"
			Write-Host $(If ($WordInput -eq $RandomWord) {"Correct"} Else {"Incorrect"}) -Fore $(If ($WordInput -eq $RandomWord) {"Green"} Else {"Red"})
			Write-Host $(If ($WordInput -ne $RandomWord) {"Correct: $RandomWord"})
			If (!$Count) {Write-Host 'Literally "guessed" without listening' -Fore "Red"} ElseIf ($WordInput -eq $RandomWord) {Write-Host $(Switch ($Count) {2{"Listened twice"} 1{"Listened once"} Default{"Listened $Count times"}}) -Fore $(Switch ($Count) {1{"Green"} Default{"Yellow"}})} Else {Write-Host}
			Write-Host (@"
{0:f2}s
[Escape]: Return to menu
[R/Enter]: Retry
[P]: Play morse
"@ -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
			$MorseGameStopwatch.Reset()
			While ($True) {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
				{"R", "Enter" -contains $_} {Continue GameLoop1}
				"P" {PlayMorse PlayMorse (([Char[]]$RandomWord | % {$MorseToLetter[$_.ToString()]}) -Join " ")}
				"Escape" {Return}
			}}}}
		}
	}
	Else {
		([Ref]$AutoReturn).Value = 3
		:GameLoop1 While ($True) {
			$RandomWord = Random $Dict
			$MorseGameStopwatch.Start()
			#$OldScreenPos = (GetEntireBufferContents), $Host.UI.RawUI.CursorPosition
			$Morse = MorseInput $RandomWord
			$RandomWordMorse = ([Char[]]$RandomWord | % {If ($_ -ne " ") {$MorseToLetter[$_.ToString()]} Else {"/"}}) -Join " "
			$MorseGameStopwatch.Stop()
			Write-Host "Input: $Morse"
			Write-Host $(If ($Morse -eq $RandomWordMorse) {"Correct"} Else {"Incorrect"}) -Fore $(If ($Morse -eq $RandomWordMorse) {"Green"} Else {"Red"})
			Write-Host $(If ($Morse -ne $RandomWordMorse) {"Correct: $RandomWordMorse"})
			Write-Host
			Write-Host (@"
{0:f2}s
[Escape]: Return to menu
[R/Enter]: Retry
[P]: Play morse
"@ -f ($MorseGameStopwatch.ElapsedMilliseconds / 1000))
			$MorseGameStopwatch.Reset()
			While ($True) {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
				{"R", "Enter" -contains $_} {Continue GameLoop1}
				"P" {PlayMorse $RandomWordMorse}
				"Escape" {Return}
			}}}}
		}
	}
}
:MainLoop While ($True) {
	cls
	Write-Host @"
[Esc]: Quit
[1]: Learn morse code
[2]: Guess a character
[3]: Guess a word
[4]: Guess a phrase/sentence
"@
	:MenuLoop Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_) {
		{"1" -eq $_.KeyChar} {Learn}
		{"2" -eq $_.KeyChar} {GuessChar}
		{"3" -eq $_.KeyChar} {GuessWord}
		{"4" -eq $_.KeyChar} {GuessPhrase}
		{"Escape" -eq $_.Key} {Break MainLoop}
	}}}
}