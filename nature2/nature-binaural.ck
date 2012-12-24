// @title example-Binaural4.ck
// @author Hongchan Choi (hongchan@ccrma) 
// @desc A simple examplary usage of Binaural4 class
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 2

// load audio files
SndBuf buf[2];

//for output
dac.left => WvOut leftOut => blackhole;
dac.right => WvOut rightOut => blackhole;
me.sourceDir() + "/nature_binaural_left.wav" => string _captureL;
me.sourceDir() + "/nature_binaural_right.wav" => string _captureR;
_captureL => leftOut.wavFilename;
_captureR => rightOut.wavFilename;

// NOTE: set your path here otherwise the VM will fail you.
"/home/tim/220A/HW5/nature2/nature1_final.wav" => buf[0].read;
"/home/tim/220A/HW5/nature2/nature2_final.wav" => buf[1].read;

// for binaural panning
DBAP4e myout[2];
Gain g;
0.5 => g.gain;
for (0 => int i; i < 2; ++i) {
  myout[i].setMode("binaural");
  myout[i].setReverb(0.1);
  myout[i].setDelayTime([5.0, 5.0, 5.0, 5.0]);
  buf[i] => g => myout[i];
}

2.0 => float dist;

for (0 => int i; i<1090; ++i) {
  myout[0].setPosition(
    -1*Math.sin(Math.pow(i,1.2)*pi/256.0)*dist,
    -1*Math.cos(Math.pow(i,1.2)*pi/256.0)*dist
  );
  myout[1].setPosition(
    Math.cos(Math.pow(i%50,1.2)*pi/8.0)*0.3,
    Math.sin(Math.pow(i%50,1.2)*pi/8.0)*0.3
  );
  100::ms => now;
}

// close files
leftOut.closeFile();
rightOut.closeFile();

// end messages
<<<"[StereoRecorder] Finished!\nRun the following command in a terminal:\n\n">>>;
<<<"sox -M "+ _captureL + " " + _captureR + " " + "nature_binaural.wav\n\n">>>;
