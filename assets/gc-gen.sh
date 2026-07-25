#!/bin/zsh
set -x
STYLE="flat vector game achievement icon, dark near-black background, neon glow, centered single emblem, no text, clean minimal, square"
gen-image "glowing red horizontal line with a hot ember ball just above it, $STYLE" -o assets/gc/ach-firstbrink.png --aspect 1:1
gen-image "five luminous teal glass orbs in a wave arc formation, $STYLE" -o assets/gc/ach-wave5.png --aspect 1:1
gen-image "ten glass orbs descending in a deep spiral, violet and teal, $STYLE" -o assets/gc/ach-wave10.png --aspect 1:1
gen-image "burst of one hundred tiny glowing particles radiating from a popped glass orb, $STYLE" -o assets/gc/ach-pegs100.png --aspect 1:1
gen-image "pink and magenta flame aura ring, fever energy, $STYLE" -o assets/gc/ach-fever.png --aspect 1:1
gen-image "golden trophy cup made of glowing glass with ember core, $STYLE" -o assets/gc/ach-score25k.png --aspect 1:1
gen-image "hot ember ball with particle trail arcing over a red line, leaderboard emblem, $STYLE" -o assets/gc/leaderboard.png --aspect 1:1
echo GC ART DONE
