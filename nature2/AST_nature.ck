// @title AST_nature.ck
// @author Tim O'Brien (tsob@ccrma)
// from example code by Chris Chafe (cc@ccrma), Hongchan Choi (hongchan@ccrma) 
// @note amplitude/spectrum tracking using UAna ugens
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 1


// Takes guitar input and outputs 

string filename[2];
"nature1.wav" => filename[0];
"nature2.wav" => filename[1];
WvOut w[2];
dac.left => w[0] => blackhole;
dac.right => w[1] => blackhole;
filename[0] => w[0].wavFilename;
filename[1] => w[1].wavFilename;

// pipe input into analysis audio graph:
// track amplitude for gain of a resonant filtered-noise
// frequency will track centroid of the input spectrum
adc.left => FFT fft  =^ RMS rms => blackhole;
fft =^ Centroid cent => blackhole;

// setup FFT: choose high-quality transform parameters
4096 => fft.size;
Windowing.hann(fft.size() / 2) => fft.window;
20 => int overlap;
0 => int ctr;
second / samp => float srate;

// resonant low-pass filtered noise
Noise n => ResonZ r => dac.left;
BlitSaw fly => Gain fg => dac.right;

// initial gain, quality(Q) and frequency for resonz
0.0 => r.gain; 
10 => r.Q;
60 => Std.mtof => r.freq;

// initial settings for BlitSaw
0.0 => fly.freq;
0 => fly.harmonics;
0.0 => fg.gain;

// instantiate a smoother to smooth tracker results (see below)
Smooth sma, smf;
// set time constant: shorter time constant gives faster 
// response but more jittery values
sma.setTimeConstant((fft.size() / 3)::samp);
smf.setTimeConstant((fft.size() / 8)::samp);


// setGainQAndFreq()
spork ~ setGainQAndFreq();
fun void setGainQAndFreq() {
    while (true) {
        // apply smoothed values
        r.gain(sma.getLast()); // apply smoothed value to gain
        r.Q(10.0 + 30.0 * sma.getLast()); // apply smoothed value to Q
        r.freq(smf.getLast()); // apply smoothed value to freq

        fly.freq(smf.getLast()); // apply smoothed value to freq
        fg.gain(sma.getLast()/50.0); // apply smoothed value to gain
        fly.harmonics(30 * sma.getLast()$int ); // apply smoothed value to harmonics

        1::samp => now;
    }   
}

// main inf-loop
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
        30 + db * 15 => db;
        // but clip at maximum
        Math.min(100, db) => db; 
        sma.setNext(Math.dbtorms(db));      
        
        // compute spectral centroid
        cent.upchuck(); 
        cent.fval(0) * srate / 2 => float c;
        // then convert it to MIDI pitch
        c => Math.ftom => float p;
        // minus a major third
        -4 +=> p;
        // set lower boundary: prevents note too low
        Math.max(20, p) => p;
        // new freq if not noise
        if(db > 10.0) {
            smf.setNext(Math.mtof(p));
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
