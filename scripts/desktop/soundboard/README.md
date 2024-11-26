# Soundboard
This is a small lua script that implements a soundboard via linux signals. The script accomplishes its goal via a a multitude of mechanisms that work together to make this function. The script itself implements signal handlers, when appropriate signals are sent to the script process it is instructed to do one of a few actions:
1. Playing a sound to a specific sink
2. Turning to the next 'page' of sounds
3. Adjusting the audio rate
4. Reversing the audio playback

The script exports its own pid to a file in `$XDG_RUNTIME_DIR/soundboard/` as well as its state which are the primary ways of interacting with the script process and providing user-facing information for status bars and etc.

# Requirements
- One audio loopback for soundboard to route to and be used as a source for apps
- One audio loopback to combine microphone and effects (not necessary for just soundboard usage)
- Keyboard shortcut mappings to send signals to the soundboard process
- A directory of sounds named by a number and the file extension, such as 1.ogg or 14.mp3

> [!NOTE]
> The default target for playback is `effect-capture.in`, script modifications may be necessary if your effect sink is not named this.

> [!WARNING]
> Sounds may not be named 0 or end in 0 (e.g., 0.m4a and 10.mka would not be allowed). See usage section for details.

## Dependencies
- lua (only tested on 5.4)
- luaposix, which can be installed via [luarocks](https://luarocks.org/): `luarocks install luaposix`
- ffmpeg
- pipewire w/ pw-play

# Usage
Run the process with the path to the sounds directory as a parameter, either in the background from a shell manually or through a user-level service/desktop environment automatically. Then send signals to the process like so:
```sh
  kill -s <SIG> $(cat "$XDG_RUNTIME_DIR/soundboard/pid")
```

Signals can range between 34-38 or 41-49 inclusively, signals in the former control the state and the latter play the sounds.
|     signal      |     function     |
|      :---:      |------------------|
|34|Previous page                    |
|35|Next page                        |
|36|Reverse playback                 |
|37|Multiply playback speed by 1/1.25|
|38|Multiply playback speed by 1.25  |
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
