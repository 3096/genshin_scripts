#NoEnv
#Warn
SendMode Input
CoordMode, Pixel, Client

#IfWinActive ahk_class UnityWndClass


global AUTO_FISH_KEY := "^f"
global AUTO_FISH_CAUGHT_TIMEOUT := 10


; coords and pix counts are hardcoded cuz meh
; AUTO_FISH_SEARCH           - search the region for the caret X coord
; AUTO_FISH_REEL_EARLY       - a white pixel on the pull rod icon (lower right, when no bite)
; AUTO_FISH_TARGET_GLOW      - the target zone yellow glow
; AUTO_FISH_CARET_GLOW       - the caret (the pointer that moves left and right) yellow glow
; AUTO_FISH_CARET_WIDTH      - the width of caret (extended part at top and bottom)
; AUTO_FISH_CARET_LEFT_PAD   - how much room to leave when sticking the caret to the left of target zone
; AUTO_FISH_BAR_TARGET_DROP  - pixel distance from caret glow to target zone glow

global AUTO_FISH_SEARCH_CONFIRMATION_THRESHOLD := 5  ; how many times to "double check" searched bar position
global AUTO_FISH_TARGET_GLOW_COLOR := 0xC0FFFF
global AUTO_FISH_CARET_GLOW_COLOR := 0xBEFFFF
global AUTO_FISH_GLOW_COLOR_VARIANCE := 3  ; this value should ideally be 0, but just in case
global AUTO_FISH_REEL_EARLY_VARIANCE := 64  ; decrease if you're not reeling, increase if you're reeling too early

; 3840x2160
global AUTO_FISH_RESOLUTION_W := 3840
global AUTO_FISH_RESOLUTION_H := 2160

global AUTO_FISH_SEARCH_LEFT_X := 1430
global AUTO_FISH_SEARCH_TOP_Y := 146
global AUTO_FISH_SEARCH_BOTTOM_Y := 256

global AUTO_FISH_REEL_EARLY_X := 3246
global AUTO_FISH_REAL_EARLY_Y := 2000

global AUTO_FISH_CARET_WIDTH := 22
global AUTO_FISH_CARET_LEFT_PAD := 60
global AUTO_FISH_BAR_TARGET_DROP := 8

; 3440x1440
global AUTO_FISH_RESOLUTION_W := 3440
global AUTO_FISH_RESOLUTION_H := 1440

global AUTO_FISH_SEARCH_LEFT_X := 1395
global AUTO_FISH_SEARCH_TOP_Y := 98
global AUTO_FISH_SEARCH_BOTTOM_Y := 170

global AUTO_FISH_REEL_EARLY_X := 2948
global AUTO_FISH_REAL_EARLY_Y := 1334

global AUTO_FISH_CARET_WIDTH := 14
global AUTO_FISH_CARET_LEFT_PAD := 40
global AUTO_FISH_BAR_TARGET_DROP := 6

; 1920x1080
global AUTO_FISH_RESOLUTION_W := 1920
global AUTO_FISH_RESOLUTION_H := 1080

global AUTO_FISH_SEARCH_LEFT_X := 715
global AUTO_FISH_SEARCH_TOP_Y := 73
global AUTO_FISH_SEARCH_BOTTOM_Y := 128

global AUTO_FISH_REEL_EARLY_X := 1623
global AUTO_FISH_REAL_EARLY_Y := 1000

global AUTO_FISH_CARET_WIDTH := 11
global AUTO_FISH_CARET_LEFT_PAD := 30
global AUTO_FISH_BAR_TARGET_DROP := 4


Hotkey, %AUTO_FISH_KEY%, AutoFish
Return


AutoFish() {
    ; get game resolution
    hWnd := WinExist("A")
    VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
    clientW := NumGet(rect, 8, "int")
    clientH := NumGet(rect, 12, "int")

    if (clientW != AUTO_FISH_RESOLUTION_W or clientH != AUTO_FISH_RESOLUTION_H) {
        MsgBox, Current resolution is not configured.
        Return
    }
    
    searchRightX := clientW - AUTO_FISH_SEARCH_LEFT_X
    caretAvoidanceThreshold := AUTO_FISH_CARET_WIDTH * 2
    caretUpperY := -1
    caretLowerY := -1
    barTargetUpperY := -1
    barTargetLowerY := -1

    ; check for pull-rod icon to detect bite
    PixelGetColor, reelEarlyColor, AUTO_FISH_REEL_EARLY_X, AUTO_FISH_REAL_EARLY_Y
    StringRight, recastKey, AUTO_FISH_KEY, 1
    Loop {
        PixelSearch, Px, Py
            , AUTO_FISH_REEL_EARLY_X, AUTO_FISH_REAL_EARLY_Y
            , AUTO_FISH_REEL_EARLY_X, AUTO_FISH_REAL_EARLY_Y
            , reelEarlyColor, AUTO_FISH_REEL_EARLY_VARIANCE, Fast
        if(ErrorLevel == 1) {
            Break
        }
        if (GetKeyState("Space", "P") or GetKeyState("LButton", "P")) {
            Return
        }
        Sleep, 16
    }
    Click

    ; search for bar location (yes, this sometimes moves around for some reason)
    ; thanks, syn! <3
    lastFoundY := -1
    lastFoundSameCount := 0
    Loop {
        PixelSearch, Px, Py
            , AUTO_FISH_SEARCH_LEFT_X, AUTO_FISH_SEARCH_TOP_Y
            , searchRightX, AUTO_FISH_SEARCH_BOTTOM_Y
            , AUTO_FISH_CARET_GLOW_COLOR, AUTO_FISH_GLOW_COLOR_VARIANCE, Fast

        ; make sure the same pos is found multiple times to avoid reading from the starting animation
        if (!ErrorLevel) {
            if (Py == lastFoundY) {
                lastFoundSameCount := lastFoundSameCount + 1 
            } else {
                lastFoundY := Py
                lastFoundSameCount := 0
            }
        }

        if (lastFoundSameCount > AUTO_FISH_SEARCH_CONFIRMATION_THRESHOLD) {
            caretUpperY := Py - AUTO_FISH_BAR_TARGET_DROP
            caretLowerY := Py + AUTO_FISH_BAR_TARGET_DROP / 4
            barTargetUpperY := Py + AUTO_FISH_BAR_TARGET_DROP
            barTargetLowerY := Py + AUTO_FISH_BAR_TARGET_DROP * 2
            Break
        }
        lastFoundY := Py

        if (GetKeyState("Space", "P")) {
            Return
        }

        ; if entered this loop by mistake and hangs, user might try to activate auto fish again
        if (GetKeyState(recastKey, "P")) {
            AutoFish()
            Return
        }

        Sleep, 20
    }

    curTimeOutCycleCount := 0
    Loop {
        ; check for exit
        if (GetKeyState("Space", "P") or curTimeOutCycleCount > AUTO_FISH_CAUGHT_TIMEOUT) {
            Send, {Click up}
            Return
        }

        ; search color for caret/target positions
        PixelSearch, curCaretX, Py
            , AUTO_FISH_SEARCH_LEFT_X, caretUpperY
            , searchRightX, caretLowerY
            , AUTO_FISH_CARET_GLOW_COLOR, AUTO_FISH_GLOW_COLOR_VARIANCE, Fast
        if (ErrorLevel) {
            curTimeOutCycleCount := curTimeOutCycleCount + 1
            Continue
        }

        PixelSearch, curBarTargetX, Py
            , AUTO_FISH_SEARCH_LEFT_X, barTargetUpperY
            , searchRightX, barTargetLowerY
            , AUTO_FISH_TARGET_GLOW_COLOR, AUTO_FISH_GLOW_COLOR_VARIANCE, Fast
        if (ErrorLevel) {
            curTimeOutCycleCount := curTimeOutCycleCount + 1
            Continue
        }
 
        curTimeOutCycleCount := 0

        ; hold or release based on searched coords
        if ((curBarTargetX + AUTO_FISH_CARET_LEFT_PAD) > curCaretX) {
            Send, {Click down}
        } else {
            Send, {Click up}
        }
    }
}
