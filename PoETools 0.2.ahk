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

expTimerStarted := false			;variable tracking exp timer state
TTTimeout := 2500					;tooltip timeout value in milliseconds (ms)
}
;=--


; ------
; - Setup GUIs
; ------
;--=
setupGUIs()
{global

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

Gui, expcalc:Add, Text, x5  y57 w105 +Center, Run Time (mins)
Gui, expcalc:Add, Edit, x111 y55 w50 h20 vRunTime

Gui, expcalc:Add, Text, x176 y57 w60 +Center, Exp/Min
Gui, expcalc:Add, Edit, x234 y55 w80 h20 vExpPerMin
Gui, expcalc:+AlwaysOnTop
}
;=--


; ------
; - Exp/Min GUI Functions/Labels
; -
; - Function: InitialExp runs every time the contents of the edit box "Initial Experience" are changed
; - 		  FinalExp runs every time the contents of the edit box "Final Experience" are changed
; -			  StartExp runs every time the button labeled "Start Timer" is clicked
; -			  NextExp runs every time the button labeled "Next" is clicked
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
 return
}
StartExp:
{
 if(expTimerStarted)
 {
  GuiControl, expcalc:, StartExp, Start	Timer			;rename the Start button to "Start"
  elapsedTime := (A_TickCount - startTime) / 60000		;get the elapsed time in ms, then convert it to minutes
  roundedTime := Round(elapsedTime, 2)					;round the elapsed time in seconds down to 2 decimal places
  GuiControl, expcalc:, RunTime, %roundedTime%			;put the elapsed time in minutes in the proper edit box

  totalExp := FinalExp - InitialExp						;calculate the experience difference
  ExpPerMin := totalExp / elapsedTime					;get the exp per min value
  roundedExpPerMin := Round(ExpPerMin, 0)				;round the exp per min value to nearest integer 
  GuiControl, expcalc:, ExpPerMin, %roundedExpPerMin%	;put the exp per min value in the proper edit box
  
  expTimerStarted := false								;set the tracking variable to false for the timer
 }
 else
 {
  GuiControl, expcalc:, StartExp, Stop Timer
  startTime := A_TickCount
  expTimerStarted := true
 }
 return
}
NextExp:
{
 GuiControl, expcalc:, InitialExp, %FinalExp%
 GuiControl, expcalc:, FinalExp,
 GuiControl, expcalc:, ExpPerMin,
 GuiControl, expcalc:, RunTime,
 return
}
ExitExp:
Gui, expcalc:hide
return
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
; - System Tray Functions/Labels
; -
; - Function: TTTimeoutChange changes the tooltip timeout in ms to user-specified value
; - 		  TTTimeoutChange#### changes the tooltip timeout in ms to #### 
; -			  SysTrayExit exits the script when user clicks "exit"
; ------
;--= 
TTTimeoutChange5000:					;user clicks "5000ms"
TTTimeout := 5000
Menu, TTTimeoutMenu, Check, 5000ms
Menu, TTTimeoutMenu, Uncheck, 2500ms
Menu, TTTimeoutMenu, Uncheck, 1000ms
Menu, TTTimeoutMenu, Uncheck, Custom
return

TTTimeoutChange2500:					;user clicks "2500ms"
TTTimeout := 2500
Menu, TTTimeoutMenu, Uncheck, 5000ms
Menu, TTTimeoutMenu, Check, 2500ms
Menu, TTTimeoutMenu, Uncheck, 1000ms
Menu, TTTimeoutMenu, Uncheck, Custom
return

TTTimeoutChange1000:					;user clicks "1000ms"
TTTimeout := 1000
Menu, TTTimeoutMenu, Uncheck, 5000ms
Menu, TTTimeoutMenu, Uncheck, 2500ms
Menu, TTTimeoutMenu, Check, 1000ms
Menu, TTTimeoutMenu, Uncheck, Custom
return

TTTimeoutChange:						;user clicks "Custom"

TryAgain:
InputBox, TTTimeout, Change Tooltip Timeout, Input the number of milliseconds (ms) to display the tooltip for.`n(0-10000), , , , , , , , 2500

if(TTTimeout < 0 || TTTimeout > 10000)	;if the number is nonsensical, ask again
	Goto, TryAgain
Menu, TTTimeoutMenu, Uncheck, 5000ms
Menu, TTTimeoutMenu, Uncheck, 2500ms
Menu, TTTimeoutMenu, Uncheck, 1000ms
Menu, TTTimeoutMenu, Check, Custom
return


ExpMinCalc:								;user clicks "Open Exp/Min Calculator"
;get the center of the screen
midx := (A_ScreenWidth - 320) / 2

Gui, expcalc:Show, , Exp/Min Calculator				;show the window for an instant so we can modify it
WinSet, Style, -0x840000, Exp/Min Calculator		;remove the borders so it looks neat
WinMove, Exp/Min Calculator, , % midx, 2, 327, 88	;resize and position the window at top center
return


SysTrayExit:							;user clicks "Exit"
ExitApp
return
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