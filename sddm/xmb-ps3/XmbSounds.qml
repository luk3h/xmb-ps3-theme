// PS3-style menu sounds. Loaded through a Loader, so if Qt Multimedia isn't installed this
// file simply fails to load and the screen stays silent - nothing else is affected.
// The sounds in sounds/ are original, generated for this theme (see sounds/README.md in the repo).
import QtQuick
import QtMultimedia

Item {
    id: sfx
    property real volume: 0.55
    property real lastAt: 0

    function play(name) {
        var now = Date.now()
        // a "move" straight after another sound (e.g. a list resetting as a panel opens) is noise
        if (name === "move" && now - lastAt < 120) return
        lastAt = now
        var e = name === "move" ? move : name === "select" ? select : name === "back" ? back
              : name === "error" ? error : name === "open" ? open : null
        if (e) { e.stop(); e.play() }
    }

    SoundEffect { id: move;   source: "sounds/move.wav";   volume: sfx.volume }
    SoundEffect { id: select; source: "sounds/select.wav"; volume: sfx.volume }
    SoundEffect { id: back;   source: "sounds/back.wav";   volume: sfx.volume }
    SoundEffect { id: error;  source: "sounds/error.wav";  volume: sfx.volume }
    SoundEffect { id: open;   source: "sounds/open.wav";   volume: sfx.volume * 0.8 }
}
