// @title gthammond-binaural.ck
// @author Tim O'Brien (tsob@ccrma), adapted from code
// by Chris Chafe (cc@ccrma) and Hongchan Choi (hongchan@ccrma)
// @desc binaural panning and mixdown for guitar and hammond mono files
// @version chuck-1.3.1.3 / ma-0.2.2c

// depends on Binaural4 and DBAP4e

// writing signals to files...
dac.left => WvOut leftOut => blackhole;
dac.right => WvOut rightOut => blackhole;
me.sourceDir() + "/gt_hammond_left_binaural.wav" => string _captureL;
me.sourceDir() + "/gt_hammond_right_binaural.wav" => string _captureR;
_captureL => leftOut.wavFilename;
_captureR => rightOut.wavFilename;

// load audio files
SndBuf buf[2];
"/home/tim/220A/HW5/gt-hammond-jam-1_final.wav" => buf[0].read;
"/home/tim/220A/HW5/gt-hammond-jam-2_final.wav" => buf[1].read;

// for binaural panning
DBAP4e myout[2];
Gain g;
0.4 => g.gain;
for (0 => int i; i < 2; ++i) {
  myout[i].setMode("binaural");
  myout[i].setReverb(0.05);
  myout[i].setDelayTime([5.0, 5.0, 5.0, 5.0]);
  buf[i] => g => myout[i];
}

// panning code
2.0 => float dist;
myout[0].setPosition(-1.0,0.0);

for (0 => int i; i<510; ++i) {
  myout[1].setPosition(
    Math.cos(Math.pow(i,1.4)*pi/4.0+pi/4.0)*dist,
    Math.sin(Math.pow(i,1.4)*pi/4.0+pi/4.0)*dist
  );
  myout[0].setPosition(-1.0,Math.sin(i*pi/2));
  100::ms => now;
}

2::second => now;

// ------------------------------------------------------------
// finish the show
leftOut.closeFile();
rightOut.closeFile();

// print message in terminal for sox command
cherr <= "\n[score] Finished.\nMerge two products with the command below.\n\n";
cherr <= "sox -M " <= _captureL <= " " <= _captureR <= " /gt-hammond-binaural-final.wav\n\n";
