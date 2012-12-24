// @title multiTrackers_bells.ck
// @author Tim O'Brien (tsob@ccrma), from example code
//  by Chris Chafe (cc@ccrma), Hongchan Choi (hongchan@ccrma) 
// @desc 3 bells powered by one guitar input, recording to
//       four individual mono files.
// @note amplitude/frequency tracking using UAna ugens
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 1

// NOTE:
// In this setup, the guitar is directly plugged into input 1,
// i.e. adc.left, and used for analysis below.
// Input 2 (adc.right) is the guitar going through effects pedals
// and then through a Fender Pro Junior tube amp. This one is used
// for the guitar audio output.


// pipe input into analysis audio graph:
// track amplitude for amplitude of bell note
// frequency will be max bin amplitude from the spectrum
adc.left => FFT fft  =^ RMS rms => blackhole;

// choose high-quality transform parameters
4096 => fft.size;
Windowing.hann(fft.size() / 2) => fft.window;
20 => int overlap;
0 => int ctr;
second / samp => float samplerate;

//for output
string filename[4];
"birds1.wav" => filename[0]; 
"birds2.wav" => filename[1];
"birds3.wav" => filename[2]; 
"birds4.wav" => filename[3]; //guitar
WvOut w[4]; // 4 output files


// actual audio graph and parameter setting
// NOTE: gain 'g' prevents direct connection bug
adc.right => Gain g => dac.right;
// Pull samples for later binaural combination
adc.right => w[3] => blackhole;
filename[3] => w[3].wavFilename;


// 3 FM bells and smoothers
3 => int numBells; 
TubeBell bell[3];
Smooth smf[3]; // 3 smoothers

// initialization for bells
for (0 => int i; i < numBells; ++i) {
    // connect each string to dac
    bell[i] => dac.left;
    // Pull samples for later binaural combination
    bell[i] => w[i] => blackhole;
    filename[i] => w[i].wavFilename;
    // initial frequency
    60 => Std.mtof => bell[i].freq;
    bell[i].noteOff(1.0);
    // set time constant
    smf[i].setTimeConstant((fft.size() / 5)::samp); 
}

// instantiate a smoother to smooth tracker results
Smooth sma;
 // set time constant
sma.setTimeConstant((fft.size() / 2)::samp);

// setGainAndFreq(): on bell[i]
fun void setGainAndFreq(int i) {
    // apply smoothed value to gain and frequency
    bell[i].noteOn(sma.getLast());
    bell[ (i+1)%numBells ].noteOff(1.0); //turn off next bell.
    bell[i].freq(smf[i].getLast());
}


// inf-loop
while(true) {
    // hop in time by overlap amount
    (fft.size() / overlap)::samp => now;
    // then we've gotten our first bufferful
    if (ctr > overlap) {
        // compute the FFT and RMS analyses
        rms.upchuck(); 
        rms.fval(0) => float a;
        Math.rmstodb(a) => float db;
        // boost the sensitity
        30 + db * 6 => db;
        // but clip at maximum
        Math.min(90, db) => db;
        sma.setNext(Math.dbtorms(db));      
        
        0 => float max; 
        0 => int where;
        // look for a frequency peak in the spectrum
        // half of spectrum to save work
        for(0 => int i; i < fft.size() / 4; ++i) {
            if(fft.fval(i) > max) {
                fft.fval(i) => max;
                i => where;
            }
        }
        
        // get frequency of peak
        (where $ float) / fft.size() * samplerate => float f;
        // convert it to MIDI pitch
        f => Std.ftom => float p; 
        // FYI we're not rounding midi pitches here.
        
        // restrict to active input
        if(db > 30.0) {
            // usually not
            0 => int pluckSomething;
            // but pick a smoother and update anyway    
            smf[ctr % numBells].setNext(Std.mtof(p));          
            // rare event, make sure it doesn't favor one instrument
            if(ctr % 27 == 0) {
                1 => pluckSomething;
            }
            // check condition and call control function
            if (pluckSomething == 1) {
                // pick an instrument and pluck it
                setGainAndFreq(ctr % numBells); 
            }
        }
    }
    ctr++;
}


// @class Smooth
// @desc contral signal generator for smooth transition
class Smooth
{
    // audio graph
    Step in => Gain out => blackhole;
    Gain fb => out;
    out => fb;
    
    // init: smoothing coefficient, default no smoothing
    0.0 => float coef;
    initGains();
    
    // initGains()
    fun void initGains() {
        in.gain(1.0 - coef);
        fb.gain(coef);
    }
    
    // setNext(): set target value
    fun void setNext(float value) { 
        in.next(value); 
    }
    
    // getLast(): return current interpolated value
    fun float getLast() {
        1::samp => now; 
        return out.last(); 
    }
    
    // setExpo(): set smoothing directly from exponent
    fun void setExpo(float value) { 
        value => coef;
        initGains();
    }
    
    // setTimeConstant(): set smoothing duration
    fun void setTimeConstant(dur duration) {
        Math.exp(-1.0 / (duration / samp)) => coef;
        initGains();
    }
} // END OF CLASS: Smooth
