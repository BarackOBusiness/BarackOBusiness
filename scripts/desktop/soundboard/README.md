# Soundboard
This is a small lua script that implements a soundboard via linux signals. This soundboard accomplishes the goal of being a non graphical background process supporting an effectively infinite catalog of sounds complete with a small set of effects via the configuration of a multitude of mechanisms; the script itself is instructed to do a variety of things via linux signals:
1. Playing a sound to a specific sink
2. Turning to the next page of sounds
3. Adjusting the audio speed
4. Reversing the audio playback
5. Toggling reverberation effects
6. Adjusting audio pitch bending

The script exports its own pid to a file in `$XDG_RUNTIME_DIR/soundboard/` to facilitate receiving signals as well as its state to provide user-facing information for status bars and etc.

# Requirements
- One audio loopback for soundboard to route to and be used as a source for apps
- One audio loopback to combine microphone and effects (not necessary if only using soundboard as an audio source)
- Keyboard shortcut mappings to send signals to the soundboard process
- A directory of sounds named by a number and the file extension, such as 1.ogg or 14.mp3

> [!NOTE]
> The default target for playback is `effect-capture.in`, script modifications may be necessary if your effect sink is not named this.

> [!WARNING]
> Sounds may not be named 0 or end in 0 (e.g., 0.m4a and 10.mka would not be allowed). See usage section for details.

## Dependencies
- lua (tested on 5.4 and luajit)
- luaposix, which can be installed via [luarocks](https://luarocks.org/): `luarocks install luaposix`
- sox
- pipewire w/ the pw-play utility

# Usage
Run the process with the path to the sounds directory as a parameter, either in the background from a shell manually or through a user-level service/desktop environment automatically. Then send signals to the process like so:
```sh
  kill -s <SIG> $(cat "$XDG_RUNTIME_DIR/soundboard/pid")
```

Signals include the ranges 34-39,41-49, and 51-53, signal numbers in the 40s play the designated sounds whereas all else control the state where state may refer to playback effects or current sound effect page.
|     signal      |     function     |
|      :---:      |------------------|
|34|Previous page                    |
|35|Next page                        |
|36|Toggle reversed playback         |
|37|Multiply playback speed by 1/1.25|
|38|Multiply playback speed by 1.25  |
|39|Toggle reverberation             |
|51|Set audio bend 1 semitone down   |
|52|Set audio bend 1 semitone up     |
|53|Reset audio bending              |
|54|Insert echoes while reverberating|
|41|Play sound effect named x1.*     |
|42|Play sound effect named x2.*     |
|43|Play sound effect named x3.*     |
|44|Play sound effect named x4.*     |
|45|Play sound effect named x5.*     |
|46|Play sound effect named x6.*     |
|47|Play sound effect named x7.*     |
|48|Play sound effect named x8.*     |
|49|Play sound effect named x9.*     |

`x` in this case refers to the current page number, where 0 is 
