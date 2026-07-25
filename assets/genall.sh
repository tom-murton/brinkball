#!/bin/zsh
set -x
cd "/Users/tommurton/GitHub/Gaming Benchmark/runs/20260716-claude-fable-5-ultra"
# Images
gen-image "iOS app icon artwork, square, a single glowing hot ember orb hovering just above a thin bright red horizontal line near the bottom, luminous teal and violet glass orbs floating in the darkness above, near-black deep space background, neon arcade glass aesthetic, dramatic glow, centered composition, bold, high contrast, no text, no letters, no border" -o assets/gen/icon-raw.png --aspect 1:1 || echo "ICON FAILED"
gen-image "very dark atmospheric background for a mobile arcade game, portrait orientation, near-black deep indigo space with extremely faint teal and magenta nebula wisps, subtle fine grain, minimal, moody, no stars in focus, no objects, mostly pure darkness, bottom slightly darker than top" -o assets/gen/bg-nebula.png --aspect 9:16 || echo "BG FAILED"
# SFX
gen-audio "single short bright glass marble clink, one clean high note, tight, dry, arcade peg hit sound effect" -o assets/audio/ding.mp3 --type sfx --duration 1
gen-audio "soft quick air whoosh, short, light game flip sound" -o assets/audio/flip1.mp3 --type sfx --duration 1
gen-audio "punchy mid-power whoosh with subtle synth zap, short arcade launch sound" -o assets/audio/flip2.mp3 --type sfx --duration 1
gen-audio "powerful dramatic bass slam with glass shimmer tail, epic short arcade super-launch sound" -o assets/audio/brink.mp3 --type sfx --duration 2
gen-audio "low muffled sad thud, ball dropping into a void, short game life-lost sound" -o assets/audio/drain.mp3 --type sfx --duration 1
gen-audio "ascending sparkling glass chime arpeggio, celebratory, short, level clear jingle" -o assets/audio/waveclear.mp3 --type sfx --duration 2
gen-audio "energetic power-up ignition surge, rising electric synth whoosh into a warm glow, short" -o assets/audio/fever.mp3 --type sfx --duration 2
gen-audio "short moody synth game over sting, descending, dark but classy arcade" -o assets/audio/gameover.mp3 --type sfx --duration 3
# Music
gen-audio "dark ambient synthwave instrumental loop, hypnotic slow arpeggios, deep space atmosphere, steady pulse, seamless loop, no vocals, no melody spikes, calm intensity" -o assets/audio/music.mp3 --type music --duration 70
echo "ALL ASSET GEN DONE"
