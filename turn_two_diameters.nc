; ============================================================
; Two-diameter wood turning - cncLathe
;
; MACHINE CONVENTION FOR THIS LATHE:
;   Z = 0 at the chuck face (LEFT end of stock)
;   +Z points to the RIGHT, toward the free end
;   Stock occupies Z = 0 to Z = +622.3
;
; Stock:    622.3 mm long, 125.476 mm dia, 62.738 mm radius
; Section A: z1=+572.300 to z2=+311.150 -> finish radius 38 mm
; Section B: z2=+311.150 to z3=+50.000  -> finish radius 35 mm
;
; The right 50 mm (free end) and left 50 mm (chuck end) of the
; stock stay at full diameter for grip/support.
;
; Roughing depth of cut: 3 mm per pass on radius
; Section B finish: 1.5 mm per pass on radius
;
; CUT DIRECTION: tool moves from the free end (high Z)
; toward the chuck (low Z) on each pass. This keeps cutting
; forces pushing the work into the chuck.
;
; BEFORE RUNNING:
;   1. Home the X and Z axes.
;   2. Touch off so G54 X0 = spindle axis, G54 Z0 = chuck face.
;   3. Update tool.tbl with the actual turning-tool offsets.
;   4. Set spindle to a safe wood-turning speed mechanically.
;   5. Air-cut FIRST (no stock) to verify motion direction.
; ============================================================

G21       ; mm
G18       ; XZ plane - lathe
G40       ; cutter comp off
G90       ; absolute
G94       ; feed per minute

T1 M6     ; select turning tool
M3 S1     ; spindle on - speed selected mechanically
F250      ; cut feed rate mm/min

; go to safe start position - past the free end of the stock
G0 X70 Z625

; ============== SECTION A: rough z1..z3 down to r = 38 ==============
; Each pass starts at the free end (z1 = +572.3) and cuts
; toward the chuck (z3 = +50.0).

; Pass 1 - r=59.738, first cut, plunge straight down at z1
G0 Z572.3
G1 X59.738
G1 Z50
G0 X70

; Pass 2 - r=56.738, chamfered lead-in from cleared zone
G0 Z575.3
G0 X60.7
G1 X56.738 Z572.3
G1 Z50
G0 X70

; Pass 3 - r=53.738
G0 Z575.3
G0 X57.7
G1 X53.738 Z572.3
G1 Z50
G0 X70

; Pass 4 - r=50.738
G0 Z575.3
G0 X54.7
G1 X50.738 Z572.3
G1 Z50
G0 X70

; Pass 5 - r=47.738
G0 Z575.3
G0 X51.7
G1 X47.738 Z572.3
G1 Z50
G0 X70

; Pass 6 - r=44.738
G0 Z575.3
G0 X48.7
G1 X44.738 Z572.3
G1 Z50
G0 X70

; Pass 7 - r=41.738
G0 Z575.3
G0 X45.7
G1 X41.738 Z572.3
G1 Z50
G0 X70

; Pass 8 - r=38.738
G0 Z575.3
G0 X42.7
G1 X38.738 Z572.3
G1 Z50
G0 X70

; Pass 9 - finish r=38
G0 Z575.3
G0 X39.7
G1 X38 Z572.3
G1 Z50
G0 X70

; ============== SECTION B: rough z2..z3 down to r = 35 ==============
; Section B is the half closer to the chuck.
; Each pass starts at z2 (+311.15) and cuts toward z3 (+50).

; Pass 10 - r=36.5, chamfered lead-in at z2
G0 Z314.15
G0 X39
G1 X36.5 Z311.15
G1 Z50
G0 X70

; Pass 11 - finish r=35
G0 Z314.15
G0 X37.5
G1 X35 Z311.15
G1 Z50
G0 X70

; retract and end
G0 X70 Z625
M5        ; spindle off
M2        ; program end
