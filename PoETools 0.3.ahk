#NoEnv
setupGlobals()
setupGUIs()
setupSysTray()
return


; ------
; - Hotkeys
; ------
;--=
^r::
;send /remaining
IfWinActive, Path of Exile				;if PoE is the active window
   SendInput {Enter}/remaining{Enter}	;hit enter, type "/remaining" and hit enter
return

^s::
;send /oos
IfWinActive, Path of Exile				;if PoE is the active window
   SendInput {Enter}/oos{Enter}	;hit enter, type "/oos" and hit enter
return
;=--


; ------
; - Setup Global Variables
; ------
;--=
setupGlobals()
{global

ExpHistoryShowing := false			;track whether or not the history is showing
ItemTTShowItemized := true			;show itemized dps by default
ItemTTShowAttackSpd := true			;show attack speed by default
ItemTTShowILevel := true			;show item level by default
TTTimeout := 2500					;tooltip timeout value in milliseconds (ms)
}
;=--


; ------
; - Setup GUIs
; ------
;--=
setupGUIs()
{global

;-----
;- Experience Calc GUI
Gui, expcalc:Font, s8, Courier New
Gui, expcalc:Add, Text, x0  y34 w320 h15 +Center, ____________________________________________
Gui, expcalc:Add, Text, x5  y2  w80 +Center, Initial Exp
Gui, expcalc:Add, Edit, x5  y20 w80 h20 vInitialExp gInitialExp
Gui, expcalc:Add, Text, x88 y22 , -
Gui, expcalc:Add, Text, x98 y2  w80 +Center, Final Exp
Gui, expcalc:Add, Edit, x98 y20 w80 h20 vFinalExp gFinalExp

Gui, expcalc:Add, Button, x185 y19 w85 h22 vStartExp gStartExp, Start Timer
Gui, expcalc:Add, Button, x275 y19 w40 h22 vNextExp  gNextExp, Next
Gui, expcalc:Add, Button, x300 y0 w15 h16 vExitExp  gExitExp, X
Gui, expcalc:Add, Button, x138 y78 w50 h10 gHistoryExp

Loop 6					;create this many *total* run entries (current + history)
{
 if(A_Index = 1)		;if this is the first one, create it in the initial spot
 {
  yedit := 55
  ytext := 57
 }
 else if (A_Index = 2)	;the second is 50 units below that 
 {
  yedit += 36
  ytext += 36
 }
 else					;the rest are in 50 unit increments
 {
  yedit += 25
  ytext += 25
 }
 
 Gui, expcalc:Add, Text, x5  y%ytext% w105 +Center, Run Time (mins)
 Gui, expcalc:Add, Edit, x111 y%yedit% w50 h20 vRunTime%A_Index%

 Gui, expcalc:Add, Text, x176 y%ytext% w60 +Center, Exp/Min
 Gui, expcalc:Add, Edit, x234 y%yedit% w80 h20 vExpPerMin%A_Index%
}

Gui, expcalc:+AlwaysOnTop

;-----
;- Experience Calc Timer Stop Button GUI
Gui, expstop:Add, Button, x0 y0 w100 h22 gStopExp, Stop Timer
Gui, expstop:+AlwaysOnTop
}
;=--


; ------
; - Setup the System Tray Menu
; ------
;--=
setupSysTray()
{global

Menu, Tray, NoStandard

Menu, TTTimeoutMenu, Add, 5000ms, TTTimeoutChange5000
Menu, TTTimeoutMenu, Add, 2500ms, TTTimeoutChange2500
Menu, TTTimeoutMenu, Add, 1000ms, TTTimeoutChange1000
Menu, TTTimeoutMenu, Add, Custom, TTTimeoutChange

Menu, ItemTooltipOptions, Add, Change Tooltip Timeout, :TTTimeoutMenu
Menu, ItemTooltipOptions, Add, Show Itemized DPS, ShowItemized
Menu, ItemTooltipOptions, Add, Show Attack Speed, ShowAttackSpd
Menu, ItemTooltipOptions, Add, Show Item Level, ShowItemLevel

Menu, Tray, Add, ItemTooltipOptions, :ItemTooltipOptions
Menu, Tray, Add
Menu, Tray, Add, Open Exp/Min Calculator, ExpMinCalc
Menu, Tray, Add
Menu, Tray, Add, Exit, SysTrayExit

;-- Set Defaults
;- 
Menu, TTTimeoutMenu, Check, 2500ms						;check 2500ms timeout by default

if(ItemTTShowItemized)
   Menu, ItemTooltipOptions, Check, Show Itemized DPS		;check show itemized dps by default
if(ItemTTShowAttackSpd)
   Menu, ItemTooltipOptions, Check, Show Attack Speed		;check show itemized dps by default
if(ItemTTShowILevel)
   Menu, ItemTooltipOptions, Check, Show Item Level		;check show itemized dps by default
}
;=--


; ------
; - Exp/Min GUI Functions/Labels
; -
; - Function: InitialExp pushes the contents of the edit box to it's variable every time the contents change
; - 		  FinalExp pushes the contents of the edit box to it's variable every time the contents change
; -			  StartExp saves a starting counter value, hides the gui and shows the "Stop Timer" button
; -			  NextExp clears out all edit fields and moves the value in Final Experience to Initial Experience.  It also stores the result in history.
; - 		  StopExp hides the stop button, shows the exp calc GUI, gets a final counter value and calculates the difference
; ------
;--= 
InitialExp:
{
 GuiControlGet, InitialExp
 return
}
FinalExp:
{
 GuiControlGet, FinalExp
 
 if(FinalExp > 0)										;if there is something to calculate, do it
 {
  totalExp := FinalExp - InitialExp						;calculate the experience difference
  ExpPerMin := totalExp / elapsedTime					;get the exp per min value
  roundedExpPerMin := Round(ExpPerMin, 0)				;round the exp per min value to nearest integer 
  GuiControl, expcalc:, ExpPerMin1, %roundedExpPerMin%	;put the exp per min value in the proper edit box
 }
 
 return
}
StartExp:
{
 Gui, expcalc:hide										;hide the exp calc gui
  
 midx := (A_ScreenWidth - 107) / 2						;get center screen
 Gui, expstop:Show, , Exp Timer Stop Button				;show the window for an instant so we can modify it
 WinSet, Style, -0x840000, Exp Timer Stop Button		;remove the borders so it looks neat
 WinMove, Exp Timer Stop Button, , % midx, 2, 107, 29	;resize and position the window at top center
  
 startTime := A_TickCount

 return
}
NextExp:
{
 GuiControl, expcalc:, InitialExp, %FinalExp%
 GuiControl, expcalc:, FinalExp,
 
 i := 6
 
 Loop 6										;shift run time and exp/min down into history
 {
  j := i - 1
  GuiControlGet, ExpPerMin%j%, expcalc:		;push the value in the edit box to it's variable
  GuiControlGet, RunTime%j%, expcalc:		;push the value in the edit box to it's variable
  GuiControl, expcalc:, ExpPerMin%i%, % ExpPerMin%j%
  GuiControl, expcalc:, RunTime%i%, % RunTime%j%
  i -= 1
 }
 return
}
StopExp:
{
 Gui, expstop:hide
 Gui, expcalc:show
 
 elapsedTime := (A_TickCount - startTime) / 60000		;get the elapsed time in ms, then convert it to minutes
 roundedTime := Round(elapsedTime, 2)					;round the elapsed time in seconds down to 2 decimal places
 GuiControl, expcalc:, RunTime1, %roundedTime%			;put the elapsed time in minutes in the proper edit box

 return
}
HistoryExp:
{
 if(ExpHistoryIsShowing)
	WinMove, Exp/Min Calculator, , , , , 95
 else
	WinMove, Exp/Min Calculator, , , , , 223
	
 ExpHistoryIsShowing := !ExpHistoryIsShowing
 return
}
ExitExp:
{
 Gui, expcalc:hide
 return
}
;=--


; ------
; - System Tray Functions/Labels
; -
; - Function: TTTimeoutChange displays an input box for the user to change the tooltip timeout in ms
; - 		  TTTimeoutChange#### changes the tooltip timeout in ms to #### 
; -			  SysTrayExit exits the script when user clicks "exit"
; ------
;--= 
TTTimeoutChange5000:					;user clicks "5000ms"
{
 TTTimeout := 5000
 Menu, TTTimeoutMenu, Check, 5000ms
 Menu, TTTimeoutMenu, Uncheck, 2500ms
 Menu, TTTimeoutMenu, Uncheck, 1000ms
 Menu, TTTimeoutMenu, Uncheck, Custom
 return
}
TTTimeoutChange2500:					;user clicks "2500ms"
{
 TTTimeout := 2500
 Menu, TTTimeoutMenu, Uncheck, 5000ms
 Menu, TTTimeoutMenu, Check, 2500ms
 Menu, TTTimeoutMenu, Uncheck, 1000ms
 Menu, TTTimeoutMenu, Uncheck, Custom
 return
}
TTTimeoutChange1000:					;user clicks "1000ms"
{
 TTTimeout := 1000
 Menu, TTTimeoutMenu, Uncheck, 5000ms
 Menu, TTTimeoutMenu, Uncheck, 2500ms
 Menu, TTTimeoutMenu, Check, 1000ms
 Menu, TTTimeoutMenu, Uncheck, Custom
 return
}
TTTimeoutChange:						;user clicks "Custom"
{
 TryAgain:
 InputBox, TTTimeout, Change Tooltip Timeout, Input the number of milliseconds (ms) to display the tooltip for.`n(0-100000), , , , , , , , 2500

 if(TTTimeout < 0 || TTTimeout > 100000)	;if the number is nonsensical, ask again
	Goto, TryAgain
 Menu, TTTimeoutMenu, Uncheck, 5000ms
 Menu, TTTimeoutMenu, Uncheck, 2500ms
 Menu, TTTimeoutMenu, Uncheck, 1000ms
 Menu, TTTimeoutMenu, Check, Custom
 return
}
ExpMinCalc:								;user clicks "Open Exp/Min Calculator"
{
 midx := (A_ScreenWidth - 320) / 2					;get the center of the screen
 Gui, expcalc:Show, , Exp/Min Calculator			;show the GUI window
 WinSet, Style, -0x840000, Exp/Min Calculator		;remove the borders so it looks neat
 WinMove, Exp/Min Calculator, , % midx, 2, 327, 95	;resize and position the window at top center
 return
}
ShowItemized:							;user clicks "Show Itemized DPS"
{
 Menu, ItemTooltipOptions, ToggleCheck, Show Itemized DPS	;toggle check show itemized
 ItemTTShowItemized := !ItemTTShowItemized
 return
}
ShowAttackSpd:							;user clicks "Show Attack Speed"
{
 Menu, ItemTooltipOptions, ToggleCheck, Show Attack Speed	;toggle check show itemized dps
 ItemTTShowAttackSpd := ! ItemTTShowAttackSpd
 return
}
ShowItemLevel:							;user clicks "Show Item Level"
{
 Menu, ItemTooltipOptions, ToggleCheck, Show Item Level		;toggle check show itemized dps
 ItemTTShowILevel := !ItemTTShowILevel
 return
}
SysTrayExit:							;user clicks "Exit"
{
 ExitApp
 return
}
;=--


; ------
; - OnClipboardChange Function
; -
; - Function: Runs every time the data in the clipboard changes
; ------
;--=
OnClipboardChange:
IfInString, clipboard, Rarity					;only do any of this if an item is what appeared in the clipboard
{
PhysDMGMin = 0
PhysDMGMax = 0
FireDMGMin = 0
FireDMGMax = 0
ColdDMGMin = 0
ColdDMGMax = 0
LightDMGMin = 0
LightDMGMax = 0
AttackSPD = 0
ItemLevel = 0


;parse the clipboard data

Loop, parse, clipboard, `n
{
 IfInString, A_LoopField, Physical Damage:		;get the line containing the weapon's physical damage
 { 
  StringGetPos, ColonPos, A_LoopField, :		;identify location of key separators to help pull apart the string
  StringGetPos, HyphenPos, A_LoopField, -
  StringGetPos, ParenthPos, A_LoopField, (
  StringLen, Length, A_LoopField
  
												;pull out the minimum damage value
  StringMid, PhysDMGMin, A_LoopField, ColonPos + 3, HyphenPos - ColonPos - 2
  
  If(Length > 30)								;if the physical damage is "(augmented)", pull out the maximum damage value
    StringMid, PhysDMGMax, A_LoopField, HyphenPos + 2, ParenthPos - HyphenPos - 2
  Else											;if physical damage is not modified, pull out the maximum damage value
	StringMid, PhysDMGMax, A_LoopField, HyphenPos + 2, Length - HyphenPos - 2
  
  ;MsgBox %A_LoopField%`nColon At: %ColonPos%`nHyphen At: %HyphenPos%`nParenth At: %ParenthPos%`nLength: %Length%`n>%PhysDMGMin%< - >%PhysDMGMax%<
  
  Continue
 }

 IfInString, A_LoopField, Fire Damage			;get the line containing the weapon's fire damage
 { 
  IfInString, A_LoopField, Adds					;make sure this is an "adds #-# fire damage" affix and not "#% increased fire damage"
  {
   StringGetPos, HyphenPos, A_LoopField, -		;identify location of key separators to help pull apart the string
   StringGetPos, FPos, A_LoopField, F
   StringLen, Length, A_LoopField
  
												;pull out the minimum damage value
   StringMid, FireDMGMin, A_LoopField, 6, HyphenPos - 5
												;pull out the maximum damage value
   StringMid, FireDMGMax, A_LoopField, HyphenPos + 2, FPos - HyphenPos - 2
  
   ;MsgBox %A_LoopField%`nHyphen At: %HyphenPos%`nF Pos: %FPos%`nLength: %Length%`n>%FireDMGMin%< - >%FireDMGMax%<

   Continue
  }
 }
 
 IfInString, A_LoopField, Cold Damage			;get the line containing the weapon's cold damage
 { 
  IfInString, A_LoopField, Adds					;make sure this is an "adds #-# cold damage" affix and not "#% increased cold damage"
  {
   StringGetPos, HyphenPos, A_LoopField, -		;identify location of key separators to help pull apart the string
   StringGetPos, CPos, A_LoopField, C
   StringLen, Length, A_LoopField
  
												;pull out the minimum damage value
   StringMid, ColdDMGMin, A_LoopField, 6, HyphenPos - 5
												;pull out the maximum damage value
   StringMid, ColdDMGMax, A_LoopField, HyphenPos + 2, CPos - HyphenPos - 2
  
   ;MsgBox %A_LoopField%`nHyphen At: %HyphenPos%`nC Pos: %CPos%`nLength: %Length%`n>%ColdDMGMin%< - >%ColdDMGMax%<
 
   Continue
  }
 }
 
 IfInString, A_LoopField, Lightning Damage		;get the line containing the weapon's lightning damage
 { 
  IfInString, A_LoopField, Adds					;make sure this is an "adds #-# lightning damage" affix and not "#% increased lightning damage"
  {
   StringGetPos, HyphenPos, A_LoopField, -		;identify location of key separators to help pull apart the string
   StringGetPos, LPos, A_LoopField, L
   StringLen, Length, A_LoopField
  
												;pull out the minimum damage value
   StringMid, LightDMGMin, A_LoopField, 6, HyphenPos - 5
												;pull out the maximum damage value
   StringMid, LightDMGMax, A_LoopField, HyphenPos + 2, LPos - HyphenPos - 2
  
   ;MsgBox %A_LoopField%`nHyphen At: %HyphenPos%`nL Pos: %LPos%`nLength: %Length%`n>%LightDMGMin%< - >%LightDMGMax%<
 
   Continue
  }
 }
 
 IfInString, A_LoopField, Attacks per Second:	;get the line containing the weapon's attacks per second
 {
  StringGetPos, ColonPos, A_LoopField, :		;identify location of key separators to help pull apart the string
  StringGetPos, ParenthPos, A_LoopField, (
  StringLen, Length, A_LoopField
  
												;pull out the attack speed
  StringMid, AttackSPD, A_LoopField, ColonPos + 2
  
  If(Length > 30)								;if the attack speed is "(augmented)", pull out the attack speed
    StringMid, AttackSPD, A_LoopField, ColonPos + 3, ParenthPos - ColonPos - 3
  Else											;if attack speed is not modified, pull out the attack speed
	StringMid, AttackSPD, A_LoopField, ColonPos + 3, Length - ColonPos - 3

  ;MsgBox %A_LoopField%`nColon At: %ColonPos%`nLength: %Length%`n>%AttackSPD%<

  Continue
 }
 
 IfInString, A_LoopField, Itemlevel:			;get the line containing the weapon's item level
 {
  StringGetPos, ColonPos, A_LoopField, :		;identify location of key separators to help pull apart the string
  StringLen, Length, A_LoopField
  
												;pull out the item level
  StringMid, ItemLevel, A_LoopField, ColonPos + 3, 2

  ;MsgBox %A_LoopField%`nColon At: %ColonPos%`nLength: %Length%`n>%ItemLevel%<
 
  Continue
 }
}

SetFormat, Float, 1								;set precision for floating point
PhysDPS := ((PhysDMGMin + PhysDMGMax) / 2 ) * AttackSPD
FireDPS := ((FireDMGMin + FireDMGMax) / 2 ) * AttackSPD
ColdDPS := ((ColdDMGMin + ColdDMGMax) / 2 ) * AttackSPD
LightDPS := ((LightDMGMin + LightDMGMax) / 2 ) * AttackSPD

TotalDPS := PhysDPS + FireDPS + ColdDPS + LightDPS


;-- build the tooltip text 

	text := "/------------------\`n"
	
if(TotalDPS > 0)
{
 if(TotalDPS < 100)				;special formatting if dps is 2 digits or 3 digits
    text .= "| Total DPS: " . TotalDPS . "    |`n"
 else
    text .= "| Total DPS: " . TotalDPS . "   |`n"
	
 if(ItemTTShowItemized)
 {
	text .= "|`t`t   |`n"
	      . "| Phys DPS:  " . PhysDPS .  "`t   |`n"
 if(FireDPS > 0)
	text .= "| Fire DPS:  " . FireDPS .  "`t   |`n"
	
 if(ColdDPS > 0)
	text .= "| Fire DPS:  " . ColdDPS .  "`t   |`n"
	
 if(LightDPS > 0)
	text .= "| Light DPS: " . LightDPS . "`t   |`n"
	
 }
 if(ItemTTShowILevel || ItemTTShowAttackSpd)
    text .= "|`t`t   |`n"
}
if(ItemTTShowAttackSpd && AttackSPD > 0)
{
	text .= "| AttackSPD: " . AttackSPD . "  |`n"

 if(ItemTTShowILevel)
	text .= "|`t`t   |`n"
}
if(ItemTTShowILevel)
{
	
	text .= "| iLevel:    " . ItemLevel . "    |`n"
}

	text .= "\------------------/`n"


;-- some trickery to change the font of the tooltip
Gui Font,s10, Courier New						;change the font of an unused GUI element
Gui Add, Text, HwndhwndStatic, % text			;put our text into the GUI element
SendMessage, 0x31,,,, ahk_id %hwndStatic%		;send message WM_GETFONT to the GUI element
font := ErrorLevel								;store the result (fontcode) into var font


;-- get the mouse cursor location
MouseGetPos, mousex, mousey


;-- display the tooltip
ToolTip, % text, mousex + 25, mousey + 20		;create the tooltip
SendMessage, 0x30, font, 1,, ahk_class tooltips_class32 ahk_exe autohotkey.exe	;send message WM_SETFONT to the tooltip


SetTimer, RemoveTT, % TTTimeout					;start the TT removal timer
}
return
;=--


RemoveTT:										;tooltip removal timer
SetTimer, RemoveTT, Off							;turn the TT removal timer off
ToolTip											;clear the TT
return