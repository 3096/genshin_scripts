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

global AUTO_FISH_TARGET_GLOW_COLOR := 0xC0FFFF
global AUTO_FISH_CARET_GLOW_COLOR := 0xBEFFFF
global AUTO_FISH_REAL_EARLY_VARIANCE := 64  ; decrease if you're not reeling, increase if you're reeling too early

; 3440x1440
global AUTO_FISH_RESOLUTION_W := 3440
global AUTO_FISH_RESOLUTION_H := 1440

global AUTO_FISH_SEARCH_LEFT_X := 1395
global AUTO_FISH_SEARCH_TOP_Y := 98
global AUTO_FISH_SEARCH_BOTTOM_Y := 170

global AUTO_FISH_REEL_EARLY_X := 2948
global AUTO_FISH_REAL_EARLY_Y := 1334

global AUTO_FISH_CARET_WIDTH := 14
global AUTO_FISH_CARET_LEFT_PAD := 50
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
global AUTO_FISH_CARET_LEFT_PAD := 38
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
    caretY := -1
    barTargetY := -1

    ; check for pull-rod icon to detect bite
    PixelGetColor, reelEarlyColor, AUTO_FISH_REEL_EARLY_X, AUTO_FISH_REAL_EARLY_Y
    Loop {
        PixelSearch, Px, Py
            , AUTO_FISH_REEL_EARLY_X, AUTO_FISH_REAL_EARLY_Y
            , AUTO_FISH_REEL_EARLY_X, AUTO_FISH_REAL_EARLY_Y
            , reelEarlyColor, AUTO_FISH_REAL_EARLY_VARIANCE, Fast
        if(ErrorLevel == 1) {
            Break
        }
        if (GetKeyState("Space", "P")) {
            Return
        }
        Sleep, 50
    }
    Click
    Sleep, 888

    ; search for bar location (yes, this sometimes moves around for some reason)
    ; thanks, syn! <3
    Loop {
        PixelSearch, Px, Py
            , AUTO_FISH_SEARCH_LEFT_X, AUTO_FISH_SEARCH_TOP_Y
            , searchRightX, AUTO_FISH_SEARCH_BOTTOM_Y
            , AUTO_FISH_CARET_GLOW_COLOR, 3, Fast

        if(!ErrorLevel) {
            caretY := Py
            barTargetY := caretY + AUTO_FISH_BAR_TARGET_DROP
            Break
        }
        if (GetKeyState("Space", "P")) {
            Return
        }
        Sleep, 50
    }

    curTimeOutCycleCount := 0
    Loop {
        curBarTargetX := -2000
        curCaretX := -1000

        ; search color for caret/target positions
        PixelSearch, curCaretX, Py
            , AUTO_FISH_SEARCH_LEFT_X, caretY
            , searchRightX, caretY
            , AUTO_FISH_CARET_GLOW_COLOR, 3, Fast
        PixelSearch, curBarTargetX, Py
            , AUTO_FISH_SEARCH_LEFT_X, barTargetY
            , searchRightX, barTargetY
            , AUTO_FISH_TARGET_GLOW_COLOR, 3, Fast
 
 		; failed to find, count for time out (done catching the fish)
        if (ErrorLevel > 0) {
            curTimeOutCycleCount := curTimeOutCycleCount + 1
        } else {
            curTimeOutCycleCount := 0
        }

        ; check for exit
        if (GetKeyState("Space", "P") or curTimeOutCycleCount > AUTO_FISH_CAUGHT_TIMEOUT) {
            Send, {Click up}
            Return
        }

        ; hold or release based on searched coords
        if ((curBarTargetX + AUTO_FISH_CARET_LEFT_PAD) > curCaretX) {
            Send, {Click down}
        } else {
            Send, {Click up}
        }
    }
}
