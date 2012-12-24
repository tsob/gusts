// @title hw4-starter.ck
// @author Chris Chafe (cc@ccrma), Hongchan Choi (hongchan@ccrma) 
// @desc A starter code for homework 4, Music220a-2012
// @note a demonstration/template for auditory streaming
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 1


// writing signals to files...
dac.left => WvOut leftOut => blackhole;
dac.right => WvOut rightOut => blackhole;
me.sourceDir() + "/gthammond_drums_left_binaural.wav" => string _captureL;
me.sourceDir() + "/gthammond_drums_right_binaural.wav" => string _captureR;
_captureL => leftOut.wavFilename;
_captureR => rightOut.wavFilename;

// load audio files
SndBuf buf[2];
"/home/tim/220A/HW5/drums/gthammond_drums_1_mono.wav" => buf[0].read;
"/home/tim/220A/HW5/drums/gthammond_drums_2_mono.wav" => buf[1].read;

// for binaural panning
DBAP4e myout[2];
Gain g;
0.4 => g.gain;
for (0 => int i; i < 2; ++i) {
  myout[i].setMode("binaural");
  myout[i].setReverb(0.1);
  myout[i].setDelayTime([5.0, 5.0, 5.0, 5.0]);
  buf[i] => g => myout[i];
}

2.0 => float dist;
myout[0].setPosition(-1.0,0.0);

for (0 => int i; i<570; ++i) {
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
cherr <= "sox -M " <= _captureL <= " " <= _captureR <= " /gthammond_drums-binaural.wav\n\n";
