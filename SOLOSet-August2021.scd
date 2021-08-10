///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*t = TempoClock.new(135/60,4);
t.permanent_(true);

t.beats;

t.stop;*/


(
~path = (PathName(thisProcess.nowExecutingPath)).pathOnly;    //defining path with samples
  // Load Samples

    ~files = SoundFile.collect(~path ++ "Samples/*");
    ~buffers = ~files.collect { |sf| var b;
	b = Buffer.read(Server.local, sf.path)};
    ~path = (PathName(thisProcess.nowExecutingPath)).pathOnly;
    ~path = ~path ++ "Samples/";
    ~windmono = Buffer.read(s, ~path ++ "IsolatedWindExpanderMONO.wav");
)

Ndef.clear  //2.

(
b = ~windmono    //3.
)

//////////////////////////////// amplitude follower////////////////////////////////////

(
(
Ndef(\followerN).fadeTime = 0.01;
Ndef(\followerN, {|followerInputGain=1, followerCut=10000,gate1=1,gate2=1|

var follower, snd, followerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )),loop:1);

	follower = Amplitude.ar(LPF.ar(snd * followerInputGain * 1 , followerCut), attackTime:0.1, releaseTime:0.3).linlin(0.0, 0.9, 0.0, 0.99);

	followerInterrupted = Gate.ar(follower,LFPulse.kr(1.33,0.5).linlin(0,1,gate1,gate2));
}));

(
Ndef(\followerInterruptedN).fadeTime = 0.01;
Ndef(\followerInterruptedN, {|followerInputGain=1, followerCut=2000|
		var follower, snd, followerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )));

	follower = Amplitude.ar(LPF.ar(snd * followerInputGain * 1 , followerCut), attackTime:0.1, releaseTime:0.3).linlin(0.0, 0.99, 0.0, 0.999);

	followerInterrupted = Gate.ar(follower,LFPulse.kr(1.33,0.5).linlin(0,1,1,1));
}));

//linlin(0,1,0,0) == stop control data
//linlin (0,1,1,1) == play control data without interruption (gate just doesn't work)

//////

(
Ndef(\followerFlippedN).fadeTime = 0.01;
Ndef(\followerFlippedN, {|followerInputGain=1, followerCut=10000, gate1=1,gate2=1|

		var follower, snd, followerRescaled, followerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )),loop:1);

	follower = Amplitude.ar(LPF.ar(snd * followerInputGain * 1 , followerCut), attackTime:0.1, releaseTime:0.3).linlin(0.0, 0.99, 0.0, 0.99);

	followerRescaled = follower.linlin(0.0, 0.99, 0.99, 0.0);

	followerInterrupted = Gate.ar(followerRescaled,LFPulse.kr(1.33,0.5).linlin(0,1,gate1,gate2));
}));

//////
(
Ndef(\followerscaled1N).fadeTime = 0.01;
Ndef(\followerscaled1N, {|followerInputGain=1, followerCut=10000, minval=0.0, maxval=1.0, gate1=1, gate2=1|
			var follower, snd, followerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )),loop:1);


	follower = Amplitude.ar(LPF.ar(snd * followerInputGain , followerCut), attackTime:0.01, releaseTime:0.3).linlin(0.0, 0.99, minval, maxval);

	followerInterrupted = Gate.ar(follower,LFPulse.kr(1.33,0.5).linlin(0,1,gate1,gate2));
}));


(
Ndef(\followerscaled2N).fadeTime = 0.01;
Ndef(\followerscaled2N, {|followerInputGain=1, followerCut=10000, minval=0.0, maxval=1.0, gate1=1, gate2=1|
			var follower, snd, followerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )),loop:1);


	follower = Amplitude.ar(LPF.ar(snd * followerInputGain , followerCut), attackTime:0.01, releaseTime:0.3).linlin(0.0, 0.99, minval, maxval);

	followerInterrupted = Gate.ar(follower,LFPulse.kr(1.33,0.5).linlin(0,1,gate1,gate2));
}));

(
Ndef(\followerscaled3N).fadeTime = 0.01;
Ndef(\followerscaled3N, {|followerInputGain=1, followerCut=10000, minval=0.0, maxval=1.0, gate1=1, gate2=1|
			var follower, snd, followerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )),loop:1);


	follower = Amplitude.ar(LPF.ar(snd * followerInputGain , followerCut), attackTime:0.01, releaseTime:0.3).linlin(0.0, 0.99, minval, maxval);

	followerInterrupted = Gate.ar(follower,LFPulse.kr(1.33,0.5).linlin(0,1,gate1,gate2));
}));
)

///////////////////////////////spectral centroid tracker///////////////////////////////
//1. allocate a Buffer + setup OSC responder
(
s = Server.local;
c = Buffer.alloc(s, 44100 * 10.0, 1);                                    // a ten seconds 1 channel Buffer
~sb = Buffer.alloc(s, 2048);
)
((
Ndef(\centroid).fadeTime=0.01;
Ndef(\centroid, { |rate=1, minval=20, maxval=10000, gate1=1, gate2=1|

	var  input,fft, tracker, snd, trackerRescaled, trackerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )),loop:1);
    fft = FFT(~sb, snd);
    tracker = SpecCentroid.kr(fft);
    trackerRescaled = tracker.linlin(20, 20000, minval, maxval);
	trackerInterrupted = Gate.kr(trackerRescaled,LFPulse.kr(1.33,0.5).linlin(0,1,gate1,gate2));
}));

(
Ndef(\centroidRescaled1).fadeTime=0.01;
Ndef(\centroidRescaled1)[0] = { |rate=1, minval=20, maxval=10000,gate1=1,gate2=1|

	var  input,fft, tracker, snd, trackerRescaled, trackerInterrupted;

	snd = BufRd.ar(numChannels: 1, bufnum: b,
		phase: Phasor.ar( trig: 0, rate: BufRateScale.kr( b ) * 1, start: 0, end: BufFrames.kr( b )));
    fft = FFT(~sb, snd);
    tracker = SpecCentroid.kr(fft);
    trackerRescaled = tracker.linlin(20, 20000, minval, maxval);
	trackerInterrupted = Gate.kr(trackerRescaled,LFPulse.kr(1.33,0.5).linlin(0,1,gate1,gate2));
});
)

///////////////////////////////////////////////FM synthesis///////////////////////////////////////////////////////

(
SynthDef("ginoFM", {arg carfreq=300, carfreq2=250, modfreq=550, modfreq2=650,minfreqfilt1=0.1, minfreqfilt2=0.1,maxfreqfilt1=3,maxfreqfilt2=3, amp=1,minindex=0, maxindex=1000,minindex2=0,maxindex2=1000,atk=0.01,release=5;
			var sound1, sound2, out1, out2, envelope, reverb, reverb2,signal;
	sound1 = DFM1.ar(PMOsc.ar(carfreq, modfreq, LinCongL.ar(rrand(0.01,0.1)).range(minindex,maxindex), 0, 0.1), LinCongL.ar(rrand(0.1, 5)).range(100,10000),0.5,1,0) * 0.5;
	sound2 = DFM1.ar(PMOsc.ar(carfreq2, modfreq2, LinCongL.ar(rrand(0.01, 0.1)).range(minindex2,maxindex2), 0, 0.1), LinCongL.ar(rrand(0.1, 2)).range(100,10000),0.5,1,0) * 0.5;
	envelope = EnvGen.ar(Env.perc(atk,release,1),doneAction:2);
	signal = sound1 + sound2;
	reverb = GVerb.ar(signal,roomsize:2, revtime:3, damping:0.99, inputbw: 1, drylevel:1);
	out1 = Out.ar(4, reverb * envelope * amp);
	}).add;
)

(
Pbindef(\a,\instrument, \ginoFM,
		   \carfreq, Tdef(\pitches1),
		   \modfreq, Tdef(\pitchesmod1),
		    \carfreq2, Tdef(\pitches2),
          //\modfreq2, Tdef(\pitchesmod2),
	     \modfreq2, Pseq([500, 1000, 500, 800],inf),
	    \minindex, 10,
	    \maxindex, 1000,
	    \minindex2, 10,
	   \maxindex2, 1000,
	   \atk, 6,
	   //\atk, 0.01,
	   \release, Pwhite(10,20,inf),
	  \amp, 3.0,
	//\dur, Pwhite(10,20,inf),
	\dur, Pwhite(0.5,4,inf),
).play;
)

Pbindef(\a).stop

y = Synth("gino").free


Tdef(\pitches1, Pseq([60,64,62,58,66,60,69,72].midicps,inf));  //first this
Tdef(\pitches2, Pseq([50,60,82,78,60,66,49,72].midicps,inf)); //first this

Tdef(\pitches1, Pseq([50,64,56,62,69,64,62,72].midicps,inf));  //then this melodie
Tdef(\pitches2, Pseq([62,60,62].midicps,inf)); //then this melodie

Tdef(\pitches1, Prand([50,64,56,62,69,64,62,72].midicps,inf));  //melodie random
Tdef(\pitches2, Prand([62,60,62].midicps,inf)); //melodie random



Tdef(\pitches1, Pseq([60,64,65,58,66,60,69,72].midicps,inf));  //first this
Tdef(\pitches2, Pseq([60,64,65,58,66,60,69,72].midicps,inf)); //first this
Tdef(\pitchesmod1, Pseq([1020, 1050, 120, 1050],inf));



Tdef(\pitchesmod1, Pseq([1000, 3000, 5000, 1000],inf));
Tdef(\pitchesmod1, Pseq([5000, 1000, 5000, 1000],inf));

Tdef(\pitchesmod1, Pseq([1020, 1050, 1020, 1050],inf));
//Tdef(\pitches2, Pseq([80,100,120,150],inf));
Tdef(\pitches2, Pseq([800,1000,1020,1500],inf));

Tdef(\pitches2, Pseq([50,60,82,78,60,66,59,72].midicps,inf)); //first this

Tdef(\pitchesmod2, Pseq([500, 1000, 500, 800],inf));



(
Ndef(\feedback2).fadeTime = 5;
Ndef(\feedback2, {|feedback= 1.0001, delay=0.01,matchlength=0.01,freeze=0|
	var sig, input, sound,control,output;

	sig = In.ar(4,2);

	input = sig + LocalIn.ar(8);

	sound = DelayC.ar(input, 1, Saw.ar( { 500.rand } ! 8).range(delay,delay*1.1));

	    LocalOut.ar( sound * feedback * rrand(0.99,0.99999));
		Limiter.ar( Splay.ar(sound) * 0.1)

}).play(4,2);
)

Ndef(\feedback2).stop(30)

/////////////////////////////////////////////////////noisy textures///////////////////////////////////////////////////
////////////////////////////////////////////////////output 8-9///////////////////////////////////////////////////////

///////////////noise high rough//////////////////
(
Ndef(\sound5).fadeTime = 15;
Ndef(\sound5)[0] =  {|amploc=0.8, freqLo=100, amp=1.5| RLPF.ar((SinOsc.ar([10, 20]).mod(LFNoise1.ar(1000)) * 0.5 ), freqLo, 0.1, 0.01) * amploc * amp};
Ndef(\sound5)[1] =  {|amploc=1, freqHi=10000, densityHi=100| RHPF.ar((SinOsc.ar([10,20]).mod(LFNoise1.ar(densityHi)) * 0.5), freqHi, 0.1, 0.5) * amploc};
Ndef(\sound5)[2] = \filter -> { |in, amp=1| (in * amp)};
)

//2-3
Ndef(\sound5).xset(\amp, 3.5);                                     //unmap ndef on GLOBAL AMP
Ndef(\sound5).xset(\freqHi, 5000);   //parti a 8000
Ndef(\sound5).xset(\freqLo, 100);
Ndef(\sound5).xset(\densityHi, 5000);   //parti giocando con la density


Ndef(\sound5).play(8,2)
Ndef(\sound5).clear
Ndef(\sound5).stop(10)


/////////////////////noise fastidioso microsound + granulato concreto//////////////////
(
Ndef(\sound3front).fadeTime = 8;
Ndef(\sound3front)[0] =  {|amploc=0.1, freqnoise=50, filterq=0.5|FreeVerb.ar(RLPF.ar(LFDClipNoise.ar(freqnoise,0.1), 100, filterq, 0.1), 0.33, 0.5) * amploc ! 2};
Ndef(\sound3front)[1] = {|amploc=1.0,freqHi=10000, freqnoise2=500, filterq=0.5| RHPF.ar(LFDClipNoise.ar(freqnoise2,0.1), freqHi, filterq, 1) * amploc ! 2};
Ndef(\sound3front)[2] = \filter -> {|in, amp=1| ( in * amp)};
)

(
Ndef(\processUnit).fadeTime = 0.008;
Ndef(\processUnit)[0] = {|density=500, amp=1,dur=0.05,ratio=0.001| GrainIn.ar(2,Dust.ar(density),dur,PitchShift.ar(Ndef(\sound3front).ar,0.1,ratio,0.4,0.4),0) * amp};
)

Ndef(\sound3front).xset(\freqnoise2,1000)
Ndef(\sound3front).xset(\amp, 3.0)

Ndef(\sound3front).play(8,2)
Ndef(\sound3front).stop(5)

Ndef(\processUnit).xset(\amp, 3.0)
Ndef(\processUnit).play(8,2)
Ndef(\processUnit).stop(0.5)


/////////////////////////////blip sides + effetti granulazione
(
(
Ndef(\sound3sides).fadeTime = 15;
Ndef(\sound3sides)[0] = {|amplow=0.01, freqLo=80,filterq=0.5, freqBlip=20| RLPF.ar(FreeVerb.ar((Blip.ar(freqBlip, 10, 0.88) * amplow), mix: 0.1, room: 0.7), freqLo, filterq, 0.7)};
Ndef(\sound3sides)[1] = {|amploc=0.3, freqHi=10000,filterq=0.5, freqBlip=20,harmBlip=1000| RHPF.ar(FreeVerb.ar((Blip.ar(freqBlip, harmBlip, 0.88) * amploc), mix: 0.1, room: 0.7), freqHi, filterq, 1)};
Ndef(\sound3sides)[2] = \filter -> {|in, amp=3.0| ( in * amp)};
Ndef(\sound3sides)[3] = \filter -> {|in| Splay.ar(in,0)};
);

(
Ndef(\procUnPrimo).fadeTime=10;
Ndef(\procUnPrimo)[1] = {|ratio=0.99,delaytm=0.1,decaytm=1.0| AllpassC.ar(PitchShift.ar(Ndef(\sound3sides).ar,0.2,ratio,0.0,0.2,2.0),0.9,delaytm,decaytm,mul:4.0)};
);


(
Ndef(\procUn).fadeTime=10;
Ndef(\procUn)[1] = {|ratio=0.5|AllpassC.ar(GrainIn.ar(1,Dust.ar(500),0.1,PitchShift.ar(Ndef(\sound3sides).ar, 0.1, ratio, 0.1, 0.2),mul:0.3),0.5,0.1,1)}
);

(
Ndef(\procUn2).fadeTime=10;
Ndef(\procUn2)[1] = { SinOsc.ar([20,10]).mod((SinOsc.ar([6000,8000]).cubed(Ndef(\procUn).ar)) * 0.56)}
);
)

Ndef(\sound3sides).play(8,2)
Ndef(\sound3sides).stop(10)

Ndef(\procUnPrimo).play(8,2)
Ndef(\procUnPrimo).stop(2)

Ndef(\procUn).play(8,2)
Ndef(\procUn).stop(10)

Ndef(\procUn2).play(8,2)
Ndef(\procUn2).stop(10)


Ndef(\sound3sides).xset(\harmBlip, 1000)
Ndef(\sound3sides).xset(\freqHi, 5000)
Ndef(\sound3sides).xset(\freqBlip, 10)
Ndef(\sound3sides).xset(\amp, 8.0);

Ndef(\sound3sides).play(8,2)
Ndef(\sound3sides).stop(10)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////---------RYTHMIC------------///////////////////////////////////////////////

////////hihat

(
SynthDef(\hihat, {arg   amp=1.5, freqHi=10000,densityHi=100,release=0.5, rq=0.1,delaycomb=0.01,decaycomb=0.5,freqRing=5000;
	var sig1, sig2, out, output, envelope;
    //sig2 = RHPF.ar((SinOsc.ar([4,6]).mod(LFNoise1.ar(densityHi)) * 0.5), freqHi, rq, 0.5);

	 sig2 = RHPF.ar(PinkNoise.ar(0.5),freqHi,rq,1); //originario
	//sig2 = Saw.ar([100,80]).pow(Saw.ar(freqHi,0.1)); //mod, fold2, cubed(unisono),pow(violento),
    envelope = EnvGen.ar(Env.perc(0.01,release,1), doneAction: 2);
	output = Splay.ar( sig2 * amp);
	out = Out.ar(6, output * envelope);
}).add
)

(
Pbindef(\hihatplayer,\instrument, \hihat,

	\dur, Prand([0.125,0.125,0.5,0.125,0.125,0.125],inf),
    //\dur, Prand([0.125,0.125,0.125,0.125,0.125,0.125],inf),
	\type, Pseq([Pseq([\rest],0.5), Pseq([\note],rrand(3,8)), Pseq([\rest],0.5)],inf),
	\release, Prand([0.1, 0.1, 0.1, 0.5,0.8],inf),
	\freqHi, Prand([10000,10000,8000,7500,8000,7000],inf),
	\rq, Prand([0.05, 0.01, 0.05,0.01,0.005],inf),
	\amp, 2.5,
	\freqRing, Pwrand([4000,4000,4000,4000,4000,4000],[10,10,10,10,5,2].normalizeSum,inf),
).play;
)

Pbindef(\hihatplayer).stop

///////////////////////////////////////////tamburi////////////////////////////////////////

(
SynthDef(\impulsesLow, { arg amploc=1,freqHi=150, numharm1=1000, numharm2= 1000,delaytm=1.0, decaytm=1.0,atk=0.001,amp=1, decay=10.5, feedback=0.0, delayedsig=0.0, tempolow=0.5, tempohigh=1.5, release=5,freqimpulses=0.35;
		var trigger, sig, sig2, snd, env, input1,input2,output, outsig1, outsig2, envelope, out;

	input1 = Blip.ar(freqimpulses, numharm1, 1.0);
	sig = (RHPF.ar(GVerb.ar(in:SwitchDelay.ar(input1,1,delayedsig,delaytm,feedback,40), roomsize:1, revtime:TRand.kr(3, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);
	snd = sig;
	output = Limiter.ar(snd,0.96,0.001);
	envelope = EnvGen.ar(Env.perc(0.01,release,1), doneAction: 2);

	out = Out.ar(0,output * amp * envelope);
}).add;
)

(
Pbindef(\rhythmLow, \instrument, \impulsesLow,

	\freqimpulses, 0.15,
	\dur, Pseq([0.5, 0.25, 0.5],inf),
	//\dur, Prand([Pseq([0.5,0.25,0.5]),Pseq([0.5,0.25,0.5,0.75]),Pseq([0.5,0.75,0.25,0.5])],inf),  //sempre dritta
	//\dur, Prand([Pseq([0.25,0.25,0.5]),Pseq([0.25,0.5,0.25,0.25]),Pseq([0.25,0.25,0.25,0.5])],inf),  //più fitta
	//\dur, Prand([Pseq([0.125,0.25,0.5]),Pseq([0.125,0.5,0.125,0.125]),Pseq([0.125,0.125,0.125,0.25])],inf),  //più più futta
    \amp,1,
	\freqHi, Pseq([100,200,200,150],inf),
	//\freqHi, Pseq([500,1000,800,50],inf),  //melodìa
	//\freqHi,Prand([Pseq([500,1000,800,50]), Pseq([500,800,1000,250])],inf),  //melodìa + varia
	\release, 2.8,
	\feedback, 0.0,
	\delaytm, 0.30,
	\delayedsig,0.0,
).play;
)

Pbindef(\rhythmLow).stop


(
SynthDef(\impulsesHi, {arg amploc=1,freqHi=150, numharm1=1000, numharm2= 1000,delaytm=1.0, decaytm=1.0,atk=0.001,amp=1, decay=10.5, feedback=0.0, delayedsig=0.0, tempolow=0.5, tempohigh=1.5,freqimpulses=1.0, release=5;
		var sig, sig2, snd, env, input1,input2,output, out, envelope;

	input1 = Blip.ar(freqimpulses, numharm1, 1.0);
	sig = (RHPF.ar(GVerb.ar(in:SwitchDelay.ar(input1,1,delayedsig,delaytm,feedback,40), roomsize:1, revtime:TRand.kr(3, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);
	input2 = Blip.ar(freqimpulses, numharm2, 1.0);
	snd = sig;
	envelope = EnvGen.ar(Env.perc(0.01,release,1), doneAction: 2);
	output = Limiter.ar(snd,0.96,0.001);
	out = Out.ar(2, output * amp * envelope);
}).add;
)

(
Pbindef(\rhythmsnotempo, \instrument, \impulsesHi,

	//\freqimpulses, Pseq([0.5,0.6,0.7],inf),
	\freqimpulses, Pseq([0.5,0.6,0.7,0.5,1.0],inf),

	\type, Pseq([Pseq([\rest],rrand(3,6)), Pseq([\note],rrand(2,4)), Pseq([\rest],2)],inf), //più rado
	//\type, Pseq([Pseq([\rest],rrand(2,5)), Pseq([\note],rrand(2,4)), Pseq([\rest],1)],inf), //più denso
	\dur, Pseq([0.25,0.25,0.5,1.0],inf),
	\amp,1.5,
	\release,Pseq([1.9,2.0,5.0],inf),
	\delaytm, 0.0,
	\freqHi, Prand([150,250,150,300,150,500],inf),
	\feedback, 0.0,
).play;
)


Pbindef(\rhythmsnotempo).stop

Pbindef.clear


//------------------impulses----------------------------

(
Ndef(\impulses).fadeTime = 1.0;
Ndef(\impulses)[1] = {|amploc=1,freqHi=150, numharm1=1000, numharm2= 1000,delaytm=1.0, decaytm=1.0,atk=0.001,amp=1, decay=10.5, feedback=0.0, delayedsig=0.0, tempolow=0.5, tempohigh=1.5|
		var trigger, sig, sig2, snd, env, input1,input2,output, outsig1, outsig2;

	input1 = Blip.ar(Ndef(\followerscaled1N), numharm1, 1.0);
	sig = (RHPF.ar(GVerb.ar(in:SwitchDelay.ar(input1,1,delayedsig,delaytm,feedback,40), roomsize:1, revtime:TRand.kr(3, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);
	input2 = Blip.ar(Ndef(\followerscaled1N), numharm2, 1.0);
	sig2 = (RHPF.ar(GVerb.ar(in:AllpassC.ar(input2, 40.0, delaytm,decaytm), roomsize:2, revtime:TRand.kr(2, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);

	snd = sig + sig2;
	output = Limiter.ar(snd,0.96,0.001);
})

(
Ndef(\impulsesLow).fadeTime = 1.0;
Ndef(\impulsesLow)[1] = {|amploc=1,freqHi=150, numharm1=1000, numharm2= 1000,delaytm=1.0, decaytm=1.0,atk=0.001,amp=1, decay=10.5, feedback=0.0, delayedsig=0.0, tempolow=0.5, tempohigh=1.5|
		var trigger, sig, sig2, snd, env, input1,input2,output, outsig1, outsig2;

	input1 = Blip.ar(Ndef(\followerscaled2N), numharm1, 1.0);
	sig = (RHPF.ar(GVerb.ar(in:SwitchDelay.ar(input1,1,delayedsig,delaytm,feedback,40), roomsize:1, revtime:TRand.kr(3, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);
	input2 = Blip.ar(Ndef(\followerscaled2N), numharm2, 1.0);
	sig2 = (RHPF.ar(GVerb.ar(in:AllpassC.ar(input2, 40.0, delaytm,decaytm), roomsize:2, revtime:TRand.kr(2, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);

	snd = sig + sig2;
	output = Limiter.ar(snd,0.96,0.001);
})


(
Ndef(\impulsesHi).fadeTime = 1.0;
Ndef(\impulsesHi)[1] = {|amploc=1,freqHi=150, numharm1=1000, numharm2= 1000,delaytm=1.0, decaytm=1.0,atk=0.001,amp=1, decay=10.5, feedback=0.0, delayedsig=0.0, tempolow=0.5, tempohigh=1.5|
		var trigger, sig, sig2, snd, env, input1,input2,output, outsig1, outsig2;

	//input1 = Blip.ar(Ndef(\followerscaled), numharm1, 1.0);
	//input1 = Blip.ar(TRand.kr(1.0,6.0,Impulse.ar(rrand(1.0,2.0))), numharm1, 1.0);
	sig = (RHPF.ar(GVerb.ar(in:SwitchDelay.ar(input1,1,delayedsig,delaytm,feedback,40), roomsize:1, revtime:TRand.kr(3, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);
	input2 = Blip.ar(Ndef(\followerscaled3N), numharm2, 1.0);
	sig2 = (RHPF.ar(GVerb.ar(in:AllpassC.ar(input2, 40.0, delaytm,decaytm), roomsize:2, revtime:TRand.kr(2, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);

	snd = sig + sig2;
	output = Limiter.ar(snd,0.96,0.001);
})

Ndef.clear
Synth.free





(
Ndef(\impulsesLow).fadeTime = 1.0;
Ndef(\impulsesLow)[1] = {|amploc=1,freqHi=150, numharm1=1000, numharm2= 1000,delaytm=0.2, decaytm=1.0,atk=0.001,amp=1, decay=10.5, feedback=0.0, delayedsig=0.0, tempolow=0.5, tempohigh=1.5|
		var trigger, sig, sig2, snd, env, input1,input2,output, outsig1, outsig2;

	input1 = Blip.ar(Ndef(\followerscaled2N), numharm1, 1.0);
	//input1 = Blip.ar(LFSaw.kr(0.01,0,0.3,0.41), numharm1, 1.0);
	sig = (RHPF.ar(GVerb.ar(in:SwitchDelay.ar(input1,1,delayedsig,delaytm,feedback,40), roomsize:1, revtime:TRand.kr(3, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);
	input2 = Blip.ar(Ndef(\followerscaled2N), numharm2, 1.0);
	//input2 = Blip.ar(LFSaw.kr(0.01,0,0.3,0.41), numharm1, 1.0);
	sig2 = (RHPF.ar(GVerb.ar(in:AllpassC.ar(input2, 40.0, delaytm,decaytm), roomsize:2, revtime:TRand.kr(2, 5, Dust.kr(0.1)), drylevel:0.9), freqHi, 0.2, 0.09) * amploc);

	snd = sig + sig2;
	output = Limiter.ar(snd,0.96,0.001);
})


Ndef(\impulses).play(0,2)
Ndef(\impulses).stop
Ndef(\impulsesLow).play(0,2)
Ndef(\impulsesLow).stop
Ndef(\impulsesHi).play(0,2)

Ndef(\impulses).stop

Ndef.clear


Ndef(\impulses).xset(\amp, 1);
Ndef(\impulses).xset(\freqHi, 250);
Ndef(\impulses).xset(\decay, 10.0);
Ndef(\impulses).xset(\numharm1, 1000);
Ndef(\impulses).xset(\numharm2, 1000);
Ndef(\impulses).xset(\delaytm, 0.1);           //inizio 1.0, poi 0.15 !!!!!
Ndef(\impulses).xset(\delaytm, Ndef(\centroid));
Ndef(\impulses).xset(\decaytm, 8.0);
Ndef(\impulses).xset(\feedback, 0.7);
Ndef(\impulses).xset(\delayedsig, 0.3);

Ndef(\impulsesLow).xset(\freqHi, 150);
Ndef(\impulsesLow).xset(\delaytm, 1.0);           //inizio 1.0, poi 0.15 !!!!!
Ndef(\impulsesLow).xset(\decaytm, 1.0);
Ndef(\impulsesLow).xset(\feedback, 0.0);

///////////////////////////////////////////////////////actions

///// control signals

Ndef(\centroid).xset(\minval, 0.05)  //evaluate it !!
Ndef(\centroid).xset(\maxval, 10.8)

Ndef(\followerscaled1N).xset(\minval, 0.2)   //   inizio 0.2   poi   0.3
Ndef(\followerscaled1N).xset(\maxval, 0.25)  //   inizio 0.25    poi    0.8

Ndef(\followerscaled1N).poll


Ndef(\followerscaled2N).xset(\minval, 0.2);   //   inizio 0.2
Ndef(\followerscaled2N).xset(\maxval, 0.25);  //   inizio 0.25

Ndef(\followerscaled3N).xset(\minval, 6.0)   //   inizio 0.2   poi   0.3
Ndef(\followerscaled3N).xset(\maxval, 7.0)  //   inizio 0.25    poi    0.8


Ndef(\centroidRescaled1).xset(\minval, 1000)
Ndef(\centroidRescaled1).xset(\maxval, 2000)


Ndef(\followerN).xset(\followerInputGain, 3);

Ndef(\INthresholdServer).xset(\threshold, 0.89)

