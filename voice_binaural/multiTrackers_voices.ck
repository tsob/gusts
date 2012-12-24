// @title multiTrackers_voices.ck
// @author Tim O'Brien (tsob@ccrma), adapted from code
// by Chris Chafe (cc@ccrma) and Hongchan Choi (hongchan@ccrma) 
// @desc Baby Farts
// @note amplitude/frequency tracking using UAna ugens
// @version chuck-1.3.1.3 / ma-0.2.2c
// @revision 1


// pipe input into analysis audio graph:
// track amplitude for amplitude of a StifKarp pluck
// frequency will be max bin amplitude from the spectrum
adc => FFT fft  =^ RMS rms => blackhole;

// choose high-quality transform parameters
4096 => fft.size;
Windowing.hann(fft.size() / 2) => fft.window;
20 => int overlap;
0 => int ctr;
second / samp => float samplerate;

// actual audio graph and parameter setting
// NOTE: gain 'g' prevents direct connection bug
//adc => Gain g => dac.left;

string filename[4];

"voice1.wav" => filename[0]; 
"voice2.wav" => filename[1];
"voice3.wav" => filename[2]; 
"voice4.wav" => filename[3];

// 4 VoicForms and smoohers
4 => int numVoices; 
VoicForm voices[4];
Smooth smf[4]; // 4 smoothers

WvOut w[4]; // 4 output files

// initialization for voices
for (0 => int i; i < numVoices; ++i) {
    // Pull samples from each voice
    // for later binaural combination
    voices[i] => w[i] => blackhole;
    filename[i] => w[i].wavFilename;
    
    // initial frequency
    60 => Std.mtof => voices[i].freq;
    
    voices[i].voiced(0.8);
    voices[i].unVoiced(0.2);
    //voices[i].pitchSweepRate(0.0);
    voices[i].quiet;
    
    // set time constant
    smf[i].setTimeConstant((fft.size() / 5)::samp); 
    
    // connect each voice to dac
    voices[i] => dac;
}

// instantiate a smoother to smooth tracker results
Smooth sma;
// set time constant
sma.setTimeConstant((fft.size() / 2)::samp);


// setGainAndFreq(): on karplus[i]
fun void setGainAndFreq(int i) {
    // apply smoothed value to gain and frequency
    voices[i].speak(sma.getLast());

    // shut up next voice
    voices[ (i+1)%numVoices ].quiet;
    //voices[ (i+2)%numVoices ].quiet;
    //voices[ (i+3)%numVoices ].quiet;

    voices[i].freq(smf[i].getLast());

    //voices[i].phonemeNum((sma.getLast()*128)$int);
    voices[i].phonemeNum(Std.rand2(50,100));
    
    voices[i].vibratoFreq( Std.rand2f(0.5,5.0) );
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
        // round off fraction (integer)
        //Math.floor(p) => p;
        // make it an even integer 
        //if (p % 2 == 1) {
        //    1 -=> p;
        //}
        // prevents notes too low
        //Math.max(20, p) => p;
        // prevents notes too high
        Math.min(100, p) => p;
        
        // restrict to active input
        if(db > 30.0) {
            // usually not
            0 => int singSomething;
            // but pick a smoother and update anyway    
            smf[ctr % numVoices].setNext(Std.mtof(p));          
            // rare event, make sure it doesn't favor one instrument
            if(ctr % 23 == 0) {
                1 => singSomething;
            }
            // check condition and call control function
            if (singSomething == 1) {
                // pick an voice and sing
                setGainAndFreq(ctr % numVoices); 
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
    0.5 => float coef;
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
