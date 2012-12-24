// @title tabla_binaural.ck
// @author Tim O'Brien (tsob@ccrma)
//         slightly adapted from code by
//         Hongchan Choi (hongchan@ccrma) 
// @desc Converts two mono files to a binaural spatialized mixdown
// @version chuck-1.3.1.3 / ma-0.2.2c

// load audio files
SndBuf buf[2];

//for output
dac.left => WvOut leftOut => blackhole;
dac.right => WvOut rightOut => blackhole;
me.sourceDir() + "/tabla_wind_binaural_left.wav" => string _captureL;
me.sourceDir() + "/tabla_wind_binaural_right.wav" => string _captureR;
_captureL => leftOut.wavFilename;
_captureR => rightOut.wavFilename;

// The mono input files
"/home/tim/220A/HW5/drums/tabla/tabla_wind_1_mono.wav" => buf[0].read;
"/home/tim/220A/HW5/drums/tabla/tabla_wind_2_mono.wav" => buf[1].read;

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

for (0 => int i; i<530; ++i) {
  myout[0].setPosition(
    -1*Math.sin(Math.pow(i,1.2)*pi/64.0)*dist,
    -1*Math.cos(Math.pow(i,1.2)*pi/64.0)*dist
  );
  myout[1].setPosition(
    Math.cos(Math.pow(i,1.2)*pi/64.0)*dist,
    Math.sin(Math.pow(i,1.2)*pi/64.0)*dist
  );
  100::ms => now;
}

// close files
leftOut.closeFile();
rightOut.closeFile();

// end messages
<<<"[StereoRecorder] Finished!\nRun the following command in a terminal:\n\n">>>;
<<<"sox -M "+ _captureL + " " + _captureR + " " + "tabla_binaural.wav\n\n">>>;
