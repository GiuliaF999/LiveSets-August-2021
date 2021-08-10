//////////////////////////////// amplitude follower////////////////////////////////////

(
Ndef(\follower).fadeTime = 2;
Ndef(\follower, {|followerInputGain=1, followerCut=10000|

	var follower, input, snd;
	input = SoundIn.ar(1);      //i am taking only one the left channel of the signal
	snd = CompanderD.ar(input,thresh:0.8, slopeBelow: 1.0, slopeAbove:2.0, clampTime: 0.002, relaxTime: 0.008);
	follower = Amplitude.ar(LPF.ar(snd * followerInputGain , followerCut), attackTime:0.01, releaseTime:0.1).linlin(0.0, 0.9, 0.00, 0.99);
}))
//////
(
Ndef(\followerFlipped).fadeTime = 2;
Ndef(\followerFlipped, {|followerInputGain=1, followerCut=10000|

	var follower, input, snd;
	input = SoundIn.ar(1);
	snd = CompanderD.ar(input,thresh:0.8, slopeBelow: 1.0, slopeAbove:2.0, clampTime: 0.002, relaxTime: 0.008);
	follower = Amplitude.ar(LPF.ar(snd * followerInputGain , followerCut), attackTime:0.01, releaseTime:0.1).linlin(0.0, 0.95, 0.99, 0.0).poll;
}))
//////
(
Ndef(\followerscaled1).fadeTime = 0.01;
Ndef(\followerscaled1, {|followerInputGain=1, followerCut=10000, minval=0.0, maxval=1.0|

	var follower, input, snd;

	input = SoundIn.ar(1);
	snd = CompanderD.ar(input,thresh:0.8, slopeBelow: 1.0, slopeAbove:2.0, clampTime: 0.002, relaxTime: 0.008);
	follower = Amplitude.ar(LPF.ar(snd * followerInputGain , followerCut), attackTime:0.1, releaseTime:0.3).linlin(0.0, 0.99, minval, maxval);
}))
///////////////////////////threshold detector and communication network///////////////////////////
( // This will start it but could stop it very soon again if it 'hears' it

var isPlaying = false;

OSCresponder(s.addr,'/tr', { arg time,responder,msg;
[time,responder,msg].postln;
if(isPlaying, {
		Ndef(\processUnit).stop; Ndef(\sound3).stop ; isPlaying = false
	}, { Ndef(\processUnit).stop; Ndef(\sound3).stop; isPlaying = true  })
}).add;
Ndef(\INthresholdClient, {
	var trigger, sender;
	trigger= DetectSilence.ar(Ndef(\followerFlipped).ar, 0.988,0.01);
	sender = SendTrig.ar(trigger);
});
Ndef(\INthresholdServer, {|threshold=0.987|
	var trigger, sender;
	trigger= DetectSilence.ar(Ndef(\followerFlipped).ar, threshold,0.01);
	sender = A2K.kr(trigger);
})
)

Ndef(\INthresholdServer).set(\threshold, 0.98)

/////////////////////////////////////onsets detector////////////////////////////////////


//1. allocate a Buffer + setup OSC responder
(
s = Server.local;
b = Buffer.alloc(s, 44100 * 10.0, 1);                                    // a ten seconds 1 channel Buffer
~sb = Buffer.alloc(s, 2048);
)
///////////

//2. record incoming sound into buffer
((
SynthDef(\recbuf, {|preLevel=0.5, bufnum=0|
	var input, snd;
	input = CompanderD.ar(SoundIn.ar(1), thresh:0.8, slopeBelow: 1.0, slopeAbove:2.0, clampTime: 0.002, relaxTime: 0.008);
	snd = RecordBuf.ar(input, bufnum, 0, preLevel:preLevel, doneAction:Done.freeSelf, loop:0);
}).play(s,[\bufnum, b]);
);
b.plot;
)

b.free
Synth.free
//3.detect onsets

(
Ndef(\onsets).fadeTime = 0.1;
Ndef(\onsets, {|rate =1|

	var  snd, chain, onsets, trigger, bleeps;
	snd = PlayBuf.ar(1, b, rate, loop:1);
	chain = FFT(~sb, snd);
	onsets =  Onsets.kr(chain, 1.0, \complex);   //thresh close to 0 means more detection and viceversa
	//trigger = SendTrig.kr(onsets);
})
)
//4.playback buffer (only)
(
Ndef(\bufferplayer).fadeTime = 1;
Ndef(\bufferplayer, { PlayBuf.ar(1, b, rate:1, loop:1)})
)

///////////////////////////////spectral centroid tracker///////////////////////////////
(
Ndef(\centroid).fadeTime=4.0;
Ndef(\centroid, { |rate=1, minval=20, maxval=10000|

	var  input,fft, tracker, snd, trackerRescaled;

	//snd = PlayBuf.ar(1, ~new, rate, loop:1);

	input = SoundIn.ar(1);

    snd = CompanderD.ar(input,thresh:0.8, slopeBelow: 1.0, slopeAbove:2.0, clampTime: 0.002, relaxTime: 0.008);
    fft = FFT(~sb, snd);
    tracker = SpecCentroid.kr(fft);
    trackerRescaled = tracker.linlin(20, 10000, minval, maxval);
}))

(
Ndef(\centroidRescaled).fadeTime=0.1;
Ndef(\centroidRescaled, { |rate=1, minval=20, maxval=10000|

	var  input,fft, tracker, snd, trackerRescaled;

	//snd = PlayBuf.ar(1, ~new, rate, loop:1);

	input = SoundIn.ar(1);

    snd = CompanderD.ar(input,thresh:0.8, slopeBelow: 1.0, slopeAbove:2.0, clampTime: 0.002, relaxTime: 0.008);
    fft = FFT(~sb, snd);
    tracker = SpecCentroid.kr(fft);
    trackerRescaled = tracker.linlin(20, 10000, minval, maxval);
}))

//
/////////////////////////////////////////             /////////////////////////////////////////
/////////////////////////////////////////sound/////////////////////////////////////////


//// sound triggered by onsets detector (envelopes triggered)
(
Ndef(\percs).fadeTime = 1;
Ndef(\percs, {Blip.ar(440,100, EnvGen.kr(Env.perc(0.001, 0.1,1), Ndef(\onsets).kr))});
)

(
Ndef(\percs).play;
)



///////// impulses triggered by INthresholdServer or by internal trigger  ////////////

(
Ndef(\sound7).fadeTime = 1.8;
Ndef(\sound7)[1] = {|amploc=1,freqHi=8000, numharm1=1000, numharm2= 1000,delaytm=1.0, decaytm=1.0,atk=0.01,amp=1, decay=0.1|
		var trigger, sig, sig2, snd, env, input;
	trigger = Impulse.kr(rrand(1.5,10.5));
	//trigger = (Ndef(\INthresholdServer).kr);

	   sig = (RHPF.ar(GVerb.ar(in:Blip.ar(Ndef(\followerscaled1), numharm1, 1.0), roomsize:2, revtime:TRand.kr(1, 4, Dust.kr(3)), drylevel:1.0), freqHi, 0.2, 0.1) * amploc);
	input = Blip.ar(Ndef(\followerscaled1), numharm2, 1.0);
	  sig2 = (RHPF.ar(GVerb.ar(in:AllpassC.ar(input, 5.0, delaytm,decaytm), roomsize:1, revtime:TRand.kr(0.5, 2, Dust.kr(3)), drylevel:1.0), freqHi, 0.2, 0.1) * amploc);

	env = EnvGen.kr(Env.perc(atk, decay, amp), trigger);
	snd = (sig + sig2)  * env;
})

Ndef(\sound7).play(2,2)
Ndef(\sound7).stop(2)

Ndef(\followerscaled1).set(\minval, 10.4)
Ndef(\followerscaled1).set(\maxval, 100)

Ndef(\INthresholdServer).set(\threshold, 0.973)

Ndef(\centroid).set(\minval, 0.1)
Ndef(\centroid).set(\maxval, 10)

Ndef(\centroidRescaled).set(\minval, 1000)
Ndef(\centroidRescaled).set(\maxval, 10000)

Ndef(\sound7).xset(\amp, 1.0);
Ndef(\sound7).xset(\amp, Ndef(\follower));
Ndef(\sound7).xset(\freqHi, 1050);
Ndef(\sound7).xset(\freqHi, Ndef(\centroidRescaled));
Ndef(\sound7).xset(\decay, 1.0);
Ndef(\sound7).xset(\numharm1, 700);
Ndef(\sound7).xset(\numharm1, Ndef(\centroid));
Ndef(\sound7).xset(\numharm2, 700);
Ndef(\sound7).xset(\numharm2, Ndef(\centroid));
Ndef(\sound7).xset(\delaytm, 0.1);
Ndef(\sound7).xset(\delaytm, Ndef(\centroid));



//// noise controlled by follower on panning and amplitude and by spectral centroid on hipass filtering

(

Ndef(\sound5).fadeTime = 10;
Ndef(\sound5)[0] =  {|amploc=0.3| RLPF.ar((SinOsc.ar([10, 20]).mod(LFNoise1.ar(100)) * 0.5 ), 80, 0.1, 0.1) * amploc};
Ndef(\sound5)[1] =  {|amploc=0.8, freqHi=1000,density=100|RHPF.ar((Saw.ar([10, 12]).mod(LFNoise1.ar(density)) * 0.5), freqHi, 0.05, 1) * amploc};
Ndef(\sound5)[2] = \filter -> { |in, amp=1| (in * amp)};
Ndef(\sound5)[3] = \filter -> {|in, lagTime=1, numCh=8, panCenter=2|
	var pan, out;
	pan = Lag.ar((Ndef(\follower).ar * numCh - numCh / panCenter), lagTime);
	out = (PanAz.ar(2, in, pan, 1, 2.0))};
)

(
Ndef(\processReverb).fadeTime=15;
Ndef(\processReverb)[0]={GVerb.ar(Ndef(\sound5).ar,roomsize:5,revtime:4.0,damping:0.7,drylevel:0.4, mul:0.5)}
)

Ndef(\processReverb).play(0,2)
Ndef(\processReverb).stop(20)

Ndef(\sound5).play(0,2)
Ndef(\sound5).stop(0)


//controls

Ndef(\centroid).xset(\minval, 200);
Ndef(\centroid).xset(\maxval, 6000);

Ndef(\sound5).xset(\amp, 0.0);

Ndef(\sound5).xset(\freqHi, 4000);

Ndef(\sound5).xset(\density, 400);

Ndef(\sound5).xset(\freqHi, Ndef(\centroid));


////////////////////////////////other noise controlled in the same way and granulated ////////////////////

(

Ndef(\sound3).fadeTime = 0.01;

Ndef(\sound3)[0] =  {|amploc=1.0, freqnoise=100, filterq=0.5|FreeVerb.ar(RLPF.ar(LFDClipNoise.ar(freqnoise,0.1), 100, filterq, 0.3), 0.33, 0.5) * amploc ! 2};
Ndef(\sound3)[1] = {|amploc=1.0,freqHi=10000, freqnoise2=100, filterq=0.5| RHPF.ar(LFDClipNoise.ar(freqnoise2,0.1), freqHi, filterq, 1) * amploc ! 2};
Ndef(\sound3)[2] = \filter -> {|in, amp=1| ( in * amp)};
Ndef(\sound3)[3] = \filter -> {|in, lagTime=2, numCh=8, panCenter=2|
	var pan, out;
	pan = Lag.kr((Ndef(\follower).kr * numCh - numCh / panCenter), lagTime);
	out = (PanAz.ar(2, in, pan, 1, 2.0))};
)


Ndef(\sound3).play(0,2)
Ndef(\sound3).clear
/// processing sound3

(
Ndef(\processUnit).fadeTime = 0.01;
Ndef(\processUnit)[0] = {|density=400| GrainIn.ar(2,Dust.kr(density),0.1,PitchShift.ar(Ndef(\sound3).ar,0.1,0.99,0.0,0.9))};
)

Ndef(\processUnit).play(0,2)
Ndef(\processUnit).stop
Ndef(\processUnit).clear

//controls

Ndef(\sound3).play(0,2)
Ndef(\sound3).stop

Ndef(\centroid).set(\minval, 200)
Ndef(\centroid).set(\maxval, 10000)

Ndef(\sound3).xset(\amp, 2.0)
Ndef(\sound3).xset(\amp, Ndef(\follower));
Ndef(\sound3).xset(\freqHi, 1000);
Ndef(\sound3).xset(\freqnoise, 50);
Ndef(\sound3).xset(\freqnoise2, 100);
Ndef(\sound3).xset(\freqnoise2, Ndef(\centroid));
Ndef(\sound3).xset(\freqHi, Ndef(\centroid));
Ndef(\sound3).xset(\filterq, 0.3);



////////////////////////////

//// cosa succede se uso qualcos'altro rispetto al crackle noise ? cosa usare ?
(
Ndef(\sound1).fadeTime = 0.5;
Ndef(\sound1)[0] = {|freq, amp=4.0| Crackle.ar(LinCongL.ar(freq ! 2).range(1.0,2.0), 0.5) * amp};
Ndef(\sound1)[1] = \set -> Pbind(\dur, 0.1, \freq, Pwhite(1.1,4.4));   //re-evaluate it in order to hear the percussive sound
)

(
Ndef(\sound1pitched).fadeTime = 0.5;
Ndef(\sound1pitched)[0] = { PitchShift.ar(Ndef(\sound1).ar, 0.1, 0.5,0.5,0.1)};
)
//// goes to
(
Ndef(\chaoticfilter1).fadeTime = 2;
Ndef(\chaoticfilter1)[0] = {|freq=100, rq=1| RHPF.ar(Ndef(\sound1).ar, LinCongL.ar(freq).range(80, 1000), rq,0.5)};
Ndef(\chaoticfilter1)[1] = {|freqlow=100, rq=1| RLPF.ar(Ndef(\sound1pitched).ar, LinCongL.ar(freqlow).range(800, 10000), rq,0.5)};
Ndef(\chaoticfilter1)[2] = \set -> Pbind(\dur, 0.1, \freq, Pwhite(100, 2000));
)

(
Ndef(\granulator).fadeTime = 1;
Ndef(\granulator)[0] = {|dur=0.5, density=500| GrainIn.ar(2, Dust.kr(density), dur, Ndef(\chaoticfilter1).ar, 0, maxGrains:1024, mul:4)};
)

Ndef(\chaoticfilter1).play
Ndef(\sound1pitched).stop

Ndef(\sound1).play(0,2)
Ndef(\sound1).stop
Ndef(\granulator).play(0,2)
Ndef(\granulator).stop(5)

Ndef.clear

/// goes to
/////don't move too much the roomsize, this causes glitches !!!!!!!
(
Ndef(\reverb).fadeTime = 5;
Ndef(\reverb)[0] = { GVerb.ar(Ndef(\granulator).ar, roomsize:0.5, revtime:5, damping:0.2, drylevel:1)};
)

Ndef(\granulator).play(0,2)
Ndef(\reverb).play

Ndef(\centroid).set(\minval, 20)
Ndef(\centroid).set(\maxval, 100)

Ndef(\sound1).xset(\amp, 3)
Ndef(\chaoticfilter1).xset(\freq, 10)
Ndef(\chaoticfilter1).xset(\freq, Ndef(\centroid))
Ndef(\chaoticfilter1).xset(\freqlow, Ndef(\centroid))
Ndef(\chaoticfilter1).xset(\freqlow, 40)
Ndef(\granulator).xset(\density, Ndef(\centroid))
Ndef(\granulator).xset(\density, 50)

Ndef.clear
///////////////////////////////////////////////////////actions

///// control signals

Ndef(\centroid).xset(\minval, 20)

Ndef(\centroid).xset(\maxval, 2000)

Ndef(\follower).xset(\followerInputGain, 3);

Ndef(\followerscaled1).xset(\minval, 0.1)
Ndef(\followerscaled1).xset(\maxval, 0.5)




/////////write buffer on disk
(
~new.write(sampleFormat: 'int16');
thisProcess.platform.recordingsDir +/+ "SC_" ++ Date.localtime.stamp ++ ".aiff"; // generated path
)


//////audio in monitoring block/////////

(
SynthDef(\audioIn, {
	var snd;
	snd = SoundIn.ar(1);
	Out.ar(4, snd);
}).add
)
);
y = Synth(\audioIn);
)
//stop monitoring
y.free


Ndef.clear




b.free                                //free buffer
Ndef.free
Synth.free

Ndef.clear
