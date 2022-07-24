#Requires -Version 2.0
$MorseText = $InputText = ""
$ShowLetter = $DisableInput = $False
$MorseDuration = 100, 300, 700, 100, 300, 400
$TypingMode = $AccentMode = 0
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
	Write-Selection "[R] Translation mode: " ($False, "Morse -> Text"), ($True, "Text -> Morse") $False
	
	Write-Host $MorseText -No
	If ($ShowLetter -and $MorseText) {Write-Host (" ({0}) " -f ((ToLetter $MorseText) -Replace "`n", "[ENTER]")) -No -Fore "DarkGreen"}
	Write-Host
	
	If (!$DisableInput) {Write-Host $InputText -Back "DarkBlue"} Else {Write-Host}
	
	Write-Selection "[T] Show morse letter while typing: " ($False, "OFF"), ($True, "ON") $ShowLetter
	Write-Selection "[M] Typing mode: " (0, "2 keys"), (1, "1 key") $TypingMode
	Write-Selection "[S] Input setting: " ($False, "Sound and input"), ($True, "Sound only") $DisableInput
}
$Media = new System.Media.SoundPlayer(".\morse.wav")
$StopSoundTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[0]}
$WordTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[5]}
$LetterTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[4]}
$Morse1KeyStopwatch = new System.Diagnostics.Stopwatch
$TrTimeoutTimer = new System.Timers.Timer -Prop @{AutoReset = $False; Interval = $MorseDuration[0]}
regob $StopSoundTimer "Elapsed" -Action {$Media.Stop(); If (!$DisableInput) {RestartTimer ([Ref]$LetterTimeoutTimer)}} | Out-Null
regob $WordTimeoutTimer "Elapsed" -Action {.$InputAdd " "; ReloadInputScreen} | Out-Null
regob $LetterTimeoutTimer "Elapsed" -Action {
	.$InputAdd (ToLetter $MorseText)
	.$ClearMorse
	ReloadInputScreen
	RestartTimer ([Ref]$WordTimeoutTimer)
} | Out-Null
regob $TrTimeoutTimer "Elapsed" -Source "TrTimeoutTimer"

$Dit = {If (!$DisableInput) {CancelTimeout; $MorseText += "."; ReloadInputScreen}; If ($TypingMode -eq 0) {$Media.PlayLooping(); RestartTimer ([Ref]$StopSoundTimer) $MorseDuration[3]}}
$Dah = {If (!$DisableInput) {CancelTimeout; $MorseText += "-"; ReloadInputScreen}; If ($TypingMode -eq 0) {$Media.PlayLooping(); RestartTimer ([Ref]$StopSoundTimer) $MorseDuration[4]}}
Function RestartTimer([Ref]$TimerObj, $Interval) {$TimerObj.Value.Stop(); If ($Interval -ne $Null) {$TimerObj.Value.Interval = $Interval}; $TimerObj.Value.Start()}
Function CancelTimeout() {If (!$DisableInput) {$LetterTimeoutTimer.Stop(); $WordTimeoutTimer.Stop()}}
#Register-EngineEvent "dit" -Action {[Console]::Beep(535,100)}
#Register-EngineEvent "dah" -Action {[Console]::Beep(535,300)}
ReloadInputScreen
$InputAdd = {Param ($String); $InputText += $String}
$ClearMorse = {$MorseText = ""}
Function TextToMorse {:TranslateLoop While ($True) {
	$Morse = ""
	cls
	Write-Selection "[R] Translation mode: " ($False, "Morse -> Text"), ($True, "Text -> Morse") $True
	Write-Host "Input text: " -NoNewLine
	
	($Raw = Read-Host).ToCharArray() | % {$i = 0} {
		If ($i++) {$Morse += " "}
		$Morse += $(If ($MorseToLetter[([String]$_).ToUpper()]) {$MorseToLetter[([String]$_).ToUpper()]} ElseIf ($_ -eq " ") {"/"} Else {"?"})
	}
	If (!$Raw) {Return}
	
	While ($True) {
		cls
		Write-Selection "[R] Translation mode: " ($False, "Morse -> Text"), ($True, "Text -> Morse") $True
		Write-Host @"
Input text: $Raw
Morse code:
$Morse
[P]: Play morse
[Backspace]: Another message
"@
		Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.Key) {
			"P" {For ($i = 0; $i -lt $Morse.Length; $i++) {
				$Character = $Morse[$i]
				cls
				Write-Selection "[R] Translation mode: " ($False, "Morse -> Text"), ($True, "Text -> Morse") $True
				Write-Host "Input text: $Raw"
				
				Write-Host "Morse code:"
				$OldCur = [Console]::CursorLeft, [Console]::CursorTop
				Write-Host @"
$Morse
[P]: Play morse
[Backspace]: Another message
"@
				[Console]::SetCursorPosition($OldCur[0], $OldCur[1])
				Write-Host $Morse.Substring(0, $i) -NoNewLine
				Try {If ($Morse.Substring($i, 3) -eq " / ") {Write-Host " / " -Back "DarkYellow" -NoNewLine} Else {Throw}}
				Catch {If ($Morse -eq "?") {Write-Host $Character -Back "DarkRed" -NoNewLine} Else {Write-Host $Character -Back "DarkYellow" -NoNewLine}}
				If ($MorseSkip) {$MorseSkip--; Continue}
				Switch ($Character) {
					"." {$Media.PlayLooping(); RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[0]; Wait-Event "TrTimeoutTimer" | Remove-Event; $Media.Stop()}
					"-" {$Media.PlayLooping(); RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[1]; Wait-Event "TrTimeoutTimer" | Remove-Event; $Media.Stop()}
					" " {
						Try {If ($Morse.Substring($i, 3) -eq " / ") {$MorseSkip = 2; RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[2]; Wait-Event "TrTimeoutTimer" | Remove-Event} Else {Throw}}
						Catch {RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[1]; Wait-Event "TrTimeoutTimer" | Remove-Event}
					}
					"?" {0..7 | %{$Media.PlayLooping(); RestartTimer ([Ref]$TrTimeoutTimer) $MorseDuration[0]; Wait-Event "TrTimeoutTimer" | Remove-Event; $Media.Stop()}}
				}
			}}
			{"R", "Escape" -contains $_} {Return}
			"Backspace" {Continue TranslateLoop}
		}}}
	}
}}
Try {[Console]::BufferWidth = 80} Catch {}
[Console]::BufferWidth = [Console]::WindowWidth = 80
Try {[Console]::BufferHeight = 25} Catch {}
[Console]::BufferHeight = [Console]::WindowHeight = 25
:MorseLoop While ($True) {
If ([Console]::KeyAvailable) {
	Switch ($TypingMode) {
		0 {Switch ([Console]::ReadKey($True)) {{$_.Modifiers -eq 0} {Switch ($_.KeyChar) {
			{".", "0" -contains $_} {CancelTimeout; .$Dit}
			{"-", "1" -contains $_} {CancelTimeout; .$Dah}
			"t" {$ShowLetter = !$ShowLetter; ReloadInputScreen}
			"s" {$DisableInput = !$DisableInput; ReloadInputScreen}
			"a" {If (++$AccentMode -gt 1) {$AccentMode = 0}; ReloadInputScreen}
			"m" {If (++$TypingMode -gt 1) {$TypingMode = 0}; ReloadInputScreen}
			"r" {TextToMorse; ReloadInputScreen}
			"`b" {If (!$DisableInput) {
				CancelTimeout
				If ($MorseText) {$MorseText = ""}
				ElseIf ($InputText) {$InputText = $InputText.Remove($InputText.Length - 1)}
				ReloadInputScreen
			}}
			" " {If (!$DisableInput) {CancelTimeout; $MorseText = ""; $InputText += " "; ReloadInputScreen}}
		}}}}
		1 {
			Switch ($Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").Character) {
				"t" {$ShowLetter = !$ShowLetter; ReloadInputScreen; Continue MorseLoop}
				"s" {$DisableInput = !$DisableInput; ReloadInputScreen; Continue MorseLoop}
				"a" {If (++$AccentMode -gt 1) {$AccentMode = 0}; ReloadInputScreen}
				"m" {If (++$TypingMode -gt 1) {$TypingMode = 0}; ReloadInputScreen; Continue MorseLoop}
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
			If ($Morse1KeyStopwatch.ElapsedMilliseconds -lt 200) {.$Dit} Else {.$Dah}
			$Morse1KeyStopwatch.Reset()
			If (!$DisableInput) {RestartTimer ([Ref]$LetterTimeoutTimer)}
		}
	}
}}