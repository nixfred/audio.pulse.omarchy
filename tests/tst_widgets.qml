import QtQuick
import QtTest
import ".." as Pulse

TestCase {
    name: "AudioPulseWidgets"
    when: windowShown
    // The chip only paints while it is actually on screen, so the case itself
    // has to be shown or nothing under test ever repaints.
    visible: true
    width: 400; height: 200

    Pulse.AudioChip { id: chip; width: 34; height: 25; compact: true; animate: false }

    function test_phase_advances_only_while_animated_and_visible() {
        failOnWarning(/.*/)
        chip.animate = false
        chip.phase = 0
        wait(250)
        compare(chip.phase, 0, 'a still chip must not tick')
        chip.animate = true
        tryVerify(function() { return chip.phase > 0 }, 2000)
        chip.visible = false
        var frozen = chip.phase
        wait(300)
        compare(chip.phase, frozen, 'an off-screen chip must not tick')
        chip.visible = true
        tryVerify(function() { return chip.phase > frozen }, 2000)
        chip.animate = false
    }

    function test_every_chip_kind_paints() {
        failOnWarning(/.*/)
        var kinds = ['speaker', 'headphones', 'hdmi', 'bluetooth', 'none']
        for (var i = 0; i < kinds.length; i++) {
            chip.kind = kinds[i]
            chip.level = i / 4
            chip.activity = 1 - i / 4
            wait(30)
        }
        chip.muted = true
        chip.compact = false
        chip.width = 160; chip.height = 160
        wait(60)
        chip.muted = false
    }
}
