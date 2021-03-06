#NoEnv

setupGlobals()
setupGUIs()
setupSysTray()
return



; ------
; - Setup Global Variables
; ------
;--=
setupGlobals()
{global

ExpHistoryShowing := false			;track whether or not the history is showingu
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
Gui, expcalc:Add, Text, x5  y30 w275 h15 +Center, ____________________________________________
Gui, expcalc:Add, Text, x5  y2  w70 +Center, Initial Exp
Gui, expcalc:Add, Edit, x5  y18 w73 h18 vInitialExp gInitialExp
Gui, expcalc:Add, Text, x80 y21 , -
Gui, expcalc:Add, Text, x89 y2  w70 +Center, Final Exp
Gui, expcalc:Add, Edit, x89 y18 w73 h18 vFinalExp gFinalExp

Gui, expcalc:Add, Button, x172 y2 w40 h34 vStartExp gStartExp, Start Timer
Gui, expcalc:Add, Button, x220 y2 w40 h34 vNextExp  gNextExp, Next Run
Gui, expcalc:Add, Button, x268 y2 w15 h16 vExitExp  gExitExp, X
Gui, expcalc:Add, Button, x118 y72 w50 h10 gHistoryExp

Loop 6					;create this many *total* run entries (current + history)
{
 if(A_Index = 1)		;if this is the first one, create it in the initial spot
 {
  yedit := 48
  ytext := 50
 }
 else if (A_Index = 2)	;the second is 50 units below that 
 {
  yedit += 38
  ytext += 38
 }
 else					;the rest are in 50 unit increments
 {
  yedit += 25
  ytext += 25
 }
 
 Gui, expcalc:Add, Text, x2  y%ytext% w105 +Center, Run Time (mins)
 Gui, expcalc:Add, Edit, x105 y%yedit% w47 h20 vRunTime%A_Index%

 Gui, expcalc:Add, Text, x155 y%ytext% w60 +Center, Exp/Min
 Gui, expcalc:Add, Edit, x212 y%yedit% w68 h20 vExpPerMin%A_Index%
}

Gui, expcalc:+AlwaysOnTop

;-----
;- Experience Calc Timer Stop Button GUI
Gui, expstop:Add, Button, x0 y0 w80 h20 gStopExp, Stop Timer
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

Menu, Tray, Add, Change Tooltip Timeout, :TTTimeoutMenu
Menu, Tray, Add
Menu, Tray, Add, Open Exp/Min Calculator, ExpMinCalc
Menu, Tray, Add
Menu, Tray, Add, Exit, SysTrayExit

Menu, TTTimeoutMenu, Check, 2500ms			;check 2500ms timeout by default
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
 WinMove, Exp Timer Stop Button, , % midx, 2, 108, 33	;resize and position the window at top center
  
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
	WinMove, Exp/Min Calculator, , , , , 110
 else
	WinMove, Exp/Min Calculator, , , , , 269
	
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
 midx := (A_ScreenWidth - 365) / 2					;get the center of the screen
 Gui, expcalc:Show, , Exp/Min Calculator			;show the GUI window
 WinSet, Style, -0x840000, Exp/Min Calculator		;remove the borders so it looks neat
 WinMove, Exp/Min Calculator, , % midx, 2, 365, 110	;resize and position the window at top center
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
PhysDMGMax = 0
PhysDMGMin = 0
FireDMGMin = 0
FireDMGMax = 0
ColdDMGMin = 0
ColdDMGMax = 0
LightDMGMax = 0
LightDMGMin = 0


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
  
  GuiControl, main:, PhysDMG, %PhysDMGMin% - %PhysDMGMax%
  
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
 
   GuiControl, main:, FireDMG, %FireDMGMin% - %FireDMGMax%
   
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
 
   GuiControl, main:, ColdDMG, %ColdDMGMin% - %ColdDMGMax%
   
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
 
   GuiControl, main:, LightDMG, %LightDMGMin% - %LightDMGMax%
   
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
 
  GuiControl, main:, AttackSPD, %AttackSPD%
  
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
		  . "| Total DPS: " . TotalDPS . "`t   |`n"
		  . "|`t`t   |`n"
		  . "| Phys DPS:  " . PhysDPS .  "`t   |`n"
if(FireDPS > 0)
	text .= "| Fire DPS:  " . FireDPS .  "`t   |`n"
	
if(ColdDPS > 0)
	text .= "| Fire DPS:  " . ColdDPS .  "`t   |`n"
	
if(LightDPS > 0)
	text .= "| Light DPS: " . LightDPS . "`t   |`n"
	
	text .= "|`t`t   |`n"
	      . "| AttackSPD: " . AttackSPD . "  |`n"
	      . "\------------------/`n"


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