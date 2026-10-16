// PS3-style menu sounds. Loaded through a Loader, so if Qt Multimedia isn't installed this
// file simply fails to load and the screen stays silent - nothing else is affected.
// The sounds in sounds/ are original, generated for this theme (see sounds/README.md in the repo).
//
// MediaPlayer, not SoundEffect: SoundEffect marks its sounds as notification-type "event"
// sounds, which KDE's Do Not Disturb mutes.
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
        if (!e) return
        e.position = 0
        e.play()
    }

    MediaPlayer { id: move;   source: "sounds/move.wav";   audioOutput: AudioOutput { volume: sfx.volume } }
    MediaPlayer { id: select; source: "sounds/select.wav"; audioOutput: AudioOutput { volume: sfx.volume } }
    MediaPlayer { id: back;   source: "sounds/back.wav";   audioOutput: AudioOutput { volume: sfx.volume } }
    MediaPlayer { id: error;  source: "sounds/error.wav";  audioOutput: AudioOutput { volume: sfx.volume } }
    MediaPlayer { id: open;   source: "sounds/open.wav";   audioOutput: AudioOutput { volume: sfx.volume * 0.8 } }
}
