#NoEnv

setupGui()											;create the gui window

setupGlobals()										;initialize any global variables

Gui, main:Show, h355 w295, PoE Tools 0.1			;display the gui window

return



setupGui()
{global

;build the main window gui
Gui, main:Add, Tab2, h340 w275 vTabb, Exp/Hour Calc|Weapon DPS|Raw Copied Item Data

Gui, main:Tab, Exp
Gui, main:Add, Text, x45 y72, Initial Experience
Gui, main:Add, Edit, x135 y70 w100 vInitialExp gInitialExp
Gui, main:Add, Text, x45 y102, Final Experience
Gui, main:Add, Edit, x135 y100 w100 vFinalExp gFinalExp
Gui, main:Add, Text, x45 y172, Run Time (mins)
Gui, main:Add, Edit, x135 y170 w100 vRunTime
Gui, main:Add, Text, x45 y202, Exp Per Hour
Gui, main:Add, Edit, x135 y200 w100 vExpPerHour
Gui, main:Add, Button, x35 y130 w140 h25 gStartExp vStartButton, Start
Gui, main:Add, Button, x185 y130 w65 h25 gResetExp vResetButton, Reset

Gui, main:Tab, Weapon DPS								;edit the DPS tab
Gui, main:Font, s15
Gui, main:Add, Text, x93 y45 ,Total DPS
Gui, main:Font, s20
Gui, main:Add, Edit, x90 y75 h40  w100 -VScroll +ReadOnly +Center vTotalDPS
Gui, main:Font, s10
Gui, main:Add, Text, x17 y115, _____________________________________
Gui, main:Font, s12
Gui, main:Add, Text, x150 y145, Damage
Gui, main:Add, Text, x230 y145, DPS
Gui, main:Font, s13
Gui, main:Add, Text, x20  y170 w100 Center, Physical
Gui, main:Add, Edit, x140 y170 h25 w80 -VScroll +ReadOnly +Center vPhysDMG
Gui, main:Add, Edit, x225 y170 h25 w45 -VScroll +ReadOnly +Center vPhysDPS
Gui, main:Add, Text, x20  y200 w100 Center, Fire
Gui, main:Add, Edit, x140 y200 h25 w80 -VScroll +ReadOnly +Center vFireDMG
Gui, main:Add, Edit, x225 y200 h25 w45 -VScroll +ReadOnly +Center vFireDPS
Gui, main:Add, Text, x20  y230 w100 Center, Cold
Gui, main:Add, Edit, x140 y230 h25 w80 -VScroll +ReadOnly +Center vColdDMG
Gui, main:Add, Edit, x225 y230 h25 w45 -VScroll +ReadOnly +Center vColdDPS
Gui, main:Add, Text, x20  y260 w100 Center, Lightning
Gui, main:Add, Edit, x140 y260 h25 w80 -VScroll +ReadOnly +Center vLightDMG
Gui, main:Add, Edit, x225 y260 h25 w45 -VScroll +ReadOnly +Center vLightDPS
Gui, main:Add, Text, x20  y305 w100 Center, Attack Speed
Gui, main:Add, Edit, x140 y305 h25 w130 -VScroll +ReadOnly +Center vAttackSPD

Gui, main:Tab, Raw									;edit the Raw Item Data tab
Gui, main:Font, s10
Gui, main:Add, Edit, h300 w250 +ReadOnly vRaw

Gui, main:+AlwaysOnTop


;alter the system tray context menu
Menu, Tray, NoStandard
Menu, Tray, Add, Minimize To System Tray, SysTrayMin
Menu, Tray, Check, Minimize To System Tray
Menu, Tray, Add
Menu, Tray, Add, Exit, ExitFromContext
}

setupGlobals()
{global
 minimizeToSysTray = 1								;toggle to minimize to system tray or not
 expTimerStarted := false							;on/off tracking variable for exp/hour calc
}



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
  GuiControl, main:, StartButton, Start
  elapsedTime := (A_TickCount - startTime) / 60000		;get the elapsed time in ms, then convert it to minutes
  GuiControl, main:, RunTime, %elapsedTime%
  elapsedTime := elapsedTime / 60						;convert time to hours now 
  totalExp := FinalExp - InitialExp
  SetFormat, float, 1.1
  ExpPerHour := totalExp / elapsedTime
  GuiControl, main:, ExpPerHour, %ExpPerHour%
  expTimerStarted := false
 }
 else
 {
  GuiControl, main:, StartButton, Stop
  startTime := A_TickCount
  expTimerStarted := true
 }
 return
}
ResetExp:
{
 GuiControl, main:, InitialExp,
 GuiControl, main:, FinalExp,
 GuiControl, main:, ExpPerHour,
 GuiControl, main:, RunTime,
}


;---SysTrayMin--
;
;	This runs when the user clicks the system tray context menu item "Minimize To System Tray"
;---------------
SysTrayMin:
Menu, Tray, ToggleCheck, Minimize To System Tray	;toggle checkmark on context menu item
minimizeToSysTray *= -1								;toggle tracking variable

ifWinNotExist, PoEQuickDPS							;if we're toggling and the window doesn't exist, show it
 {
  ;Gui, main:show
  Gui, main:minimize
 }
return


;---ExitFromContext--
;
;	This runs when the user clicks the system tray context menu item "Exit"
;---------------
ExitFromContext:
ExitApp
return


;---OnClipboardChange--
;
;	This runs any time the contents of the clipboard change
;---------------
OnClipboardChange:
IfInString, clipboard, Rarity						;only do any of this if an item is what appeared in the clipboard
{
GuiControl, main:, Raw, %clipboard%
Gui, main:Restore									;if the window was minimized, bring it back up automatically
GuiControl, main:Choose, Tabb, 2					;set the tab to the weapon dps tab
SetTitleMatchMode, 3
WinActivate, Path of Exile							;since restoring gives the window focus, give focus back to PoE

GuiControl, main:, PhysDMG, 0
GuiControl, main:, FireDMG, 0
GuiControl, main:, ColdDMG, 0
GuiControl, main:, LightDMG, 0
GuiControl, main:, PhysDPS, 0
GuiControl, main:, FireDPS, 0
GuiControl, main:, ColdDPS, 0
GuiControl, main:, LightDPS, 0
GuiControl, main:, AttackSPD, 0

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
 IfInString, A_LoopField, Physical Damage:			;get the line containing the weapon's physical damage
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
 }

 IfInString, A_LoopField, Fire Damage				;get the line containing the weapon's fire damage
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
  }
 }
 
 IfInString, A_LoopField, Cold Damage				;get the line containing the weapon's cold damage
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
  }
 }
 
 IfInString, A_LoopField, Lightning Damage			;get the line containing the weapon's lightning damage
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
  }
 }
 
 IfInString, A_LoopField, Attacks per Second:		;get the line containing the weapon's attacks per second
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
 }
}

SetFormat, Float, 1									;set precision for floating point
PhysDPS := ((PhysDMGMin + PhysDMGMax) / 2 ) * AttackSPD
FireDPS := ((FireDMGMin + FireDMGMax) / 2 ) * AttackSPD
ColdDPS := ((ColdDMGMin + ColdDMGMax) / 2 ) * AttackSPD
LightDPS := ((LightDMGMin + LightDMGMax) / 2 ) * AttackSPD

GuiControl, main:, PhysDPS, %PhysDPS%
GuiControl, main:, FireDPS, %FireDPS%
GuiControl, main:, ColdDPS, %ColdDPS%
GuiControl, main:, LightDPS, %LightDPS%

TotalDPS := PhysDPS + FireDPS + ColdDPS + LightDPS

GuiControl, main:, TotalDPS, %TotalDPS%
}
return


;---mainGuiClose--
;
;	This runs whenever the main GUI window is closed.
;---------------
mainGuiClose:										;exit the script when the gui is closed
ExitApp
return


;---mainGuiSize--
;
;	This runs whenever the main GUI window is resized, minimized, maximized or restored
;---------------
mainGuiSize:									
if((A_EventInfo = 1) && (minimizeToSysTray = 1))	;close the gui window when minimized so it doesn't take up task bar space
 Gui, main:hide
return