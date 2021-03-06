// @title example-Binaural4.ck
// @author Hongchan Choi (hongchan@ccrma) 
// @desc A simple examplary usage of Binaural4 class
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 2

// IMPORTANT: add Binaural4 class first!
Binaural4 b4;

// load you audio files
SndBuf buf[4];

//for output
dac.left => WvOut leftOut => blackhole;
dac.right => WvOut rightOut => blackhole;
me.sourceDir() + "/voice_left.wav" => string _captureL;
me.sourceDir() + "/voice_right.wav" => string _captureR;
_captureL => leftOut.wavFilename;
_captureR => rightOut.wavFilename;

// NOTE: set your path here otherwise the VM will fail you.
"/home/tim/220A/HW5/voice1.wav" => buf[0].read;
"/home/tim/220A/HW5/voice2.wav" => buf[1].read;
"/home/tim/220A/HW5/voice3.wav" => buf[2].read;
"/home/tim/220A/HW5/voice4.wav" => buf[3].read;

JCRev rev[4];

for(0 => int i; i < 4; ++i) {
    buf[i] => rev[i] => b4.input[i];
    rev[i].mix(0.2);
}

51::second => now;


// close files
leftOut.closeFile();
rightOut.closeFile();

// end messages
<<<"[StereoRecorder] Finished! run the following command in a terminal:">>>;
<<<"sox -M "+ _captureL + " " + _captureR + " " + "voice_binaural.wav">>>;
