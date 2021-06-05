# Jlab Compositor

Overlay gif from jlab over an animation

## Usage

    Usage: ./jlab_composite.sh -i INPUT FILE [-b BPM] [-f FPS] [-s SCALE]
                    [-o FRAME OFFSET] [-x X-OFFSET] [-y Y-OFFSET]
                    [-d DWELL] [-j <0|1>] [-g GRAVITY] [-c CYCLES] [-v <0|1>]
                    [-u <0|1>] [-p PATTERN] [-t TO_FILE]

    -i INPUT FILE
    -b BPM (default 160)
    -f FPS (default 30)
    -s SCALE (default 1.0)
    -o FRAME OFFSET (default 0)
    -x X-OFFSET (of animated balls in pixels, positive moves right)
    -y Y-OFFSET (of animated balls in pixels, positive moves down)
    -d DWELL number of beats of dwell time, between 0.0 and 2.0
    -j HIDEJUGGLER (default 1, 0 to show wireframe of juggler)  
    -g GRAVITY in cm/s^2 (default 980)
    -c CYCLES number of times through the pattern (default 1)
    -v VERBOSE (0 or 1, defualt 0)
    -u DEBUG  (0 or 1, defualt 0)
    -p PATTERN (default 3)
    -t TO_FILE (default videos/composite.mp4)

## Dependencies and installation

* bash
* perl
* ffmpeg
* JugglingLab.jar
* jlab (JugglingLab command line tool)
* ImageMagick
* GNU Coretutils

The directory containing `jlab` must be included in `$PATH`

## Tips about running `./jlab_composite.sh`

* Choose an animation backdrop file that is not *too* long or high resolution.
* Find the first frame that shows a throw from the left side of the screen (the juggler's first right-hand throw). The `frame_offset` will be frame number, minus one.
* Determine the the number of beats per minute in the input video - count the number of throws in a 10 second clip, then multiply by 6.
* You can unhide the wire frame juggler from JugglingLab using the `j=0` option.
This is useful for finding the center line of the pattern.

Supposing that you are going to draw juggling balls on top of `my_great_3ball_cascade.mp4`, which has a cadence of 210 bpm, and starts with the juggler's first right-hand throw on frame 8. The frame offset will therefore be 7.

    ./jlab_composite.sh -i my_great_3ball_cascade.mp4 -b 210 -o 7 -j 0

After some processing, this will create `./videos/composite.mp4`

Pointing your web browser to <index.html> will display the video.
