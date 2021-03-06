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

;-----
;- Trading Post Generator GUI
Gui, trade:Add, Text, x10 y5 w150 +Center gTradeMove, Click and drag here to move
Gui, trade:Add, TreeView, x10 y50 w150 h175 vTradeItems
Gui, trade:Add, Button, x10 y232 w150 h22 gTradeAddCat, Add Category
Gui, trade:Add, Button, x10 y260 w150 h22 gTradeExport, Export To Clipboard
Gui, trade:+AlwaysOnTop
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
Menu, Tray, Add, Open Trading Post Gen, TradingPostGen
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
Gui, expcalc:hide
return
;=--


; ------
; - Trade Post GUI Functions/Labels
; -
; ------
;--=
TradeMove:
PostMessage, 0xA1, 2,,,A
return

TradeAddCat:
InputBox, cat, Add Category, Input the name for the new category.
TV_Add(cat)
return

TradeExport:
ItemID := 0
clipboard := "This is the headline message.`nIGN: CharName`n`n`n"
Loop
{
 ItemID := TV_GetNext(ItemID, "Full")
 If(!ItemID)
    break
	
 ;check if item is a parent (category) or child (item)
 ;if(isParent)
 TV_GetText(ItemText, ItemID)
 clipboard .= "[b]" . ItemText . "[/b]`n`n"
 
}
return
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
InputBox, TTTimeout, Change Tooltip Timeout, Input the number of milliseconds (ms) to display the tooltip for.`n(0-100000), , , , , , , , 2500

if(TTTimeout < 0 || TTTimeout > 100000)	;if the number is nonsensical, ask again
	Goto, TryAgain
Menu, TTTimeoutMenu, Uncheck, 5000ms
Menu, TTTimeoutMenu, Uncheck, 2500ms
Menu, TTTimeoutMenu, Uncheck, 1000ms
Menu, TTTimeoutMenu, Check, Custom
return


TradingPostGen:
Gui, trade:Show, , Trading Post Generator				;show the GUI window
WinSet, Style, -0x840000, Trading Post Generator	;remove the borders so it looks neat
WinMove, Trading Post Generator, , , , 178, 299			;resize and position the window at top center
return


ExpMinCalc:								;user clicks "Open Exp/Min Calculator"
midx := (A_ScreenWidth - 320) / 2					;get the center of the screen
Gui, expcalc:Show, , Exp/Min Calculator				;show the GUI window
WinSet, Style, -0x840000, Exp/Min Calculator		;remove the borders so it looks neat
WinMove, Exp/Min Calculator, , % midx, 2, 327, 95	;resize and position the window at top center
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

Gui, trade:Default								;set the default GUI to the trade window before we see if we're building a trade list
If(TV_GetCount() > 0)							;if there exists a TreeView with greater than zero items, we probably intend to add to trade list, not parse
{
 if(TV_GetSelection() > 0)						;only add the item if the user actually selected anything
 {
  ;the format of an item link is as follows:
  ;
  ;Stash Linking ---- [linkItem location="Stash1" league="Domination" x="0" y="0"]
  ;		"location" is "Stash#" where # is the stash tab number
  ;		"league" is the league the character is in
  ;		"x" and "y" define the x,y coordinate in the stash grid of the item's top-left cell ((0,0) is top left)
  ;
  ;Inventory linking ---- [linkItem location="MainInventory" character="Name" x="0" y="0"]
  ;		"location" can be "MainInventory", "Weapon", "Helm", "BodyArmor", "Gloves", "Boots", "Belt", "Ring", "Ring2", "Amulet", "Flask"
  ;		"character" is the character name
  ;		"x" and "y" define the x,y coordinate in the inventory grid of the item's top-left cell ((0,0) is top left)
  ;			NOTE: only "MainInventory" and "Flask" can have non-zero x and y.  (Flasks go (0,0),(1,0),(2,0) etc)

  ;so first, we figure out where the mouse cursor is and use that to generate an x and a y
  ;depending also on where the mouse is, we figure out if it's in a stash tab
  TV_Add(clipboard, TV_GetSelection())
  TV_Modify(TV_GetSelection(), "+Expand")
 }
 return
}

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