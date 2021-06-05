#! /bin/bash

usage() {
echo "Usage: $0 -i INPUT FILE [-b BPM] [-f FPS] [-s SCALE]
                [-o FRAME OFFSET] [-x X-OFFSET] [-y Y-OFFSET]
                [-d DWELL] [-j <0|1>] [-g GRAVITY] [-c CYCLES]
                [-v <0|1>] [-u <0|1>]
                [-p PATTERN] [-t TO_FILE]

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
-t TO_FILE (output file, default videos/composite.mp4)" 1>&2;
    exit 1 
}

verbose() { if [ $verbose -eq 1 ]; then echo "$@" 1>&2; fi; }

while getopts ":i:b:f:s:o:x:y:d:j:g:c:v:u:p:t:" opt; do
    case "${opt}" in
        i)
            input_file=${OPTARG}
            ;;
        b)
            bpm=${OPTARG}
            ;;
        f)
            fps=${OPTARG}
            ;;
        s)
            scale=${OPTARG}
            ;;
        o)
            frame_offset=${OPTARG}
            ;;
        x)
            x=${OPTARG}
            ;;
        y)
            y=${OPTARG}
            ;;
        d)
            dwell=${OPTARG}
            ;;
        j)
            hidejuggler=${OPTARG}
            ;;
        g)
            gravity=${OPTARG}
            ;;
        c)
            cycles=${OPTARG}
            ;;
        p)
            pattern=${OPTARG}
            ;;
        v)
            verbose=${OPTARG}
            ;;
        d)
            to_file=${OPTARG}
            ;;
        d)
            debug=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [ -z "$input_file" ]; then
    usage
fi

if [ $debug -eq 1 ];then
    set -o vi
fi

bpm=${bpm:=160}
fps=${fps:=30}
scale=${scale:=1.0}
frame_offset=${frame_offset:=0}
pattern=${pattern:=3}
hidejuggler=${hidejuggler:=0}
dwell=${dwell:=1.0}
gravity=${gravity:=980}
cycles=${cycles:=1}
pattern=${pattern:=3}
to_file=${to_file:="videos/composite.mp4"}

# TODO: read the path of $to_file; create the directory if it doesn't
#       already exist.

verbose "  input_file = ${input_file}"
verbose "         bpm = ${bpm}"
verbose "         fps = ${fps}"
verbose "       scale = ${scale}"
verbose "frame_offset = ${frame_offset}"
verbose "     pattern = ${pattern}"


rescale() { perl -e 'printf "%d\n", $ARGV[0] * $ARGV[1]' $1 $2; }

frames () 
{ 
    local file="$1";
    local path="$(dirname "$file")";
    local extension="${file##*.}";
    local base="$(basename "$file" ".${extension}")";
    ( cd $path;
    [ ! -d frames ] && mkdir frames/;
    ffmpeg -i "$file" "frames/${base}-%04d.png" )
}

nframes () 
{ 
    local file="$1";
    local framecount="$2"
    local path="$(dirname "$file")";
    local extension="${file##*.}";
    local base="$(basename "$file" ".${extension}")";
    ( cd $path;
    [ ! -d frames ] && mkdir frames/;
    ffmpeg -i "$file" -frames $framecount "frames/${base}-%04d.png" )
}

bps () 
{ 
    perl -e 'printf "%02.2f\n", $ARGV[0]/60' $1
}

generate_gif() {
    local bpm=$1;
    local fps=$2
    local width=$3
    local height=$4
    local pattern=$5
    local prefs="slowdown=1.0;view=simple;fps=$fps;hidejugglers=$hidejuggler;width=$width;height=$height"
    local gif_file="${pattern}ball_${bpm}bpm.${width}x${height}px.gif"
    jlab togif "pattern=$pattern;dwell=$dwell;bps=$(bps $bpm);gravity=$gravity" -prefs "$prefs" -out $gif_file && echo $gif_file 2> /dev/null
    return $?
}

width=$(rescale 400 $scale)
height=$(rescale 450 $scale)

gif_file="$(generate_gif $bpm $fps $width $height $pattern)"
gif_file_base=$(basename $gif_file '.gif')

frames $gif_file

gif_frames=(frames/*.png)
frame_count=${#gif_frames[*]}

extension="${input_file##*.}";
input_file_base="$(basename "$input_file" ".${extension}")";
nframes $input_file $(( ( $frame_count * $cycles )+ $frame_offset))

[ -d frames/composite ] || mkdir frames/composite

for ((cycle=0; $cycle < $cycles; cycle++)) {
    verbose ""
    verbose "#### CYCLE $cycle ####"
    for ((i=1; $i <= $frame_count; i++)) {
        d=$(printf "%04d" $i)
        d_input=$(printf "%04d" $(((cycle*frame_count)+i+frame_offset)))
        d_output=$(printf "%04d" $(((cycle*frame_count)+i)))
        verbose "*** Converting frames/${gif_file_base}-$d.png to frames/${gif_file_base}-$d.transparent.png ***"
        convert frames/${gif_file_base}-$d.png -transparent white frames/${gif_file_base}-$d.transparent.png
        verbose "*** compositing frames/${gif_file_base}-$d.transparent.png with frames/${input_file_base}-$d_input.png *** "
        #composite frames/${gif_file_base}-$d.transparent.png frames/${input_file_base}-$d_input.png frames/composite/$d_output.out.png
        convert frames/${input_file_base}-$d_input.png frames/${gif_file_base}-$d.transparent.png -geometry +$x+$y -composite frames/composite/$d_output.out.png
    }
}

ffmpeg -framerate $fps -i frames/composite/%04d.out.png $to_file
