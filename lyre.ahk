#NoEnv
#Warn
SendMode Input

#IfWinActive ahk_class UnityWndClass

; X, Y coords for location of the ring
; for best results, avoid "success" text overlap on the chosen pixels
; below are hardcoded coords for 3440x1440 (need to change for each resolution)
;                    W       A       S       D       I       J       K       L
global KEY_CODES := ["vk57", "vk41", "vk53", "vk44", "vk49", "vk4A", "vk4B", "vk4C"]
global X_COORDS  := [994,    670,    994,    1316,   2448,   2126,   2448,   2766]
global Y_COORDS  := [545,    860,    1185,   860,    545,    860,    1184,   860]

global ACTIVATION_COLOR := 0x40E0FF
global KEY_PRESS_CYCLE_DURATION := 2
global CYCLE_SLEEP_DURATION := 5


IsSimilarColor(color0, color1, tolerance)
{
    r0 := color0 & 0xFF
    g0 := (color0 & 0xFF00) >> 8
    b0 := (color0 & 0xFF0000) >> 16

    r1 := color1 & 0xFF
    g1 := (color1 & 0xFF00) >> 8
    b1 := (color1 & 0xFF0000) >> 16,

    distance := (r0 - r1)**2 + (g0 - g1)**2 + (b1 - b0)**2
    return distance < tolerance
}

F8::
    curKeyPressCycles := []
    Loop {
        ; check for stopping
        if(GetKeyState("Space", "P")) {
            Break
        }

        for i, keyCode in KEY_CODES
        {
            if (curKeyPressCycles[i] > 0) {
                curKeyPressCycles[i] -= 1
                if (curKeyPressCycles[i] <= 0) {
                    Send {%keyCode% up}
                }

            } else {
                PixelGetColor, pixelColor, X_COORDS[i], Y_COORDS[i]
                if(IsSimilarColor(ACTIVATION_COLOR, pixelColor, 400)) {
                    Send {%keyCode% down}
                    curKeyPressCycles[i] := KEY_PRESS_CYCLE_DURATION
                }
            }
        }

        Sleep, CYCLE_SLEEP_DURATION
    }

    return
