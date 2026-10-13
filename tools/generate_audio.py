"""Blackwood original score and Foley-style synthesis. Python standard library only.
Run from the repository root: python tools/generate_audio.py
No downloaded recordings or third-party music. Deterministic 16-bit PCM assets.
"""
from array import array
from pathlib import Path
import math
import random
import wave

RATE = 22050
TAU = math.tau
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)


def save(name, data, channels=1, peak=.65):
    scale = peak / max(.001, max(abs(v) for v in data))
    pcm = array('h', (round(max(-1, min(1, v*scale))*32767) for v in data))
    import sys
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(OUT / (name+'.wav')), 'wb') as f:
        f.setnchannels(channels)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(pcm.tobytes())


def note(midi):
    return 440 * 2 ** ((midi-69)/12)


def score():
    # 16 bars, D minor / B-flat / F / C, 84 BPM. Harp, bowed pad and wooden pulse.
    beat = 60/84
    length = round(64*beat*RATE)
    left = array('f', [0])*length
    right = array('f', [0])*length

    def voice(start, duration, midi, gain, pan=0, pad=False):
        freq = note(midi)
        count = int(duration*RATE)
        for i in range(count):
            t = i/RATE
            if pad:
                env = min(1, t/.55)*min(1, (duration-t)/.9)
                value = (math.sin(TAU*freq*t)+.25*math.sin(TAU*(freq*1.002)*t)
                         +.12*math.sin(TAU*freq*2*t))*env*.5
            else:
                env = min(1,t/.009)*math.exp(-3.8*t/duration)*min(1,(duration-t)/.05)
                value = (math.sin(TAU*freq*t)+.32*math.sin(TAU*freq*2*t)*math.exp(-4*t)
                         +.14*math.sin(TAU*freq*3*t)*math.exp(-8*t))*env
            index = (round(start*RATE)+i)%length
            left[index] += value*gain*(1-pan)*.5
            right[index] += value*gain*(1+pan)*.5

    chords = [[50,57,62,65],[46,53,58,62],[48,53,57,60],[48,55,60,64]]
    motif = [74,77,76,69,72,74,69,65,70,74,72,65,69,67,64,67]
    for bar in range(16):
        start = bar*4*beat
        chord = chords[bar%4]
        for j,midi in enumerate(chord):
            voice(start,4.8*beat,midi,.07,(-.4 if j%2 else .4),True)
        voice(start,3.5*beat,chord[0]-12,.11,0)
        for step in range(8):
            voice(start+step*beat/2,1.6*beat,chord[[0,2,1,3,2,1,3,1][step]]+12,
                  .10 if step%2 == 0 else .065, -.5 if step%2 else .5)
        if bar >= 4:
            for step in range(2):
                voice(start+(step*2+.5)*beat,2.8*beat,motif[((bar-4)*2+step)%16],.12,.12)
        if bar >= 8:
            voice(start, .18,38,.12,-.15)
            voice(start+2*beat,.12,50,.055,.2)
    # Circular stereo delay preserves the loop's reverb tail across its boundary.
    dry_l, dry_r = left[:],right[:]
    for delay, gain in [(.23,.18),(.47,.10),(.71,.055)]:
        offset = int(delay*RATE)
        for i in range(length):
            left[(i+offset)%length] += dry_r[i]*gain
            right[(i+offset)%length] += dry_l[i]*gain
    stereo = array('f')
    for a,b in zip(left,right):
        stereo.extend((a,b))
    save('bosque_theme',stereo,2,.55)


def effect(name, duration, base, noise=.0, chime=False, rise=False):
    rng = random.Random(name)
    data = []
    low = phase = 0.0
    for i in range(round(duration*RATE)):
        t = i/RATE
        u = t/duration
        low = .72*low+.28*rng.uniform(-1,1)
        freq = base*(1+.65*u if rise else .4+.6*math.exp(-12*u))
        phase += TAU*freq/RATE
        env = min(1,t/.004)*math.exp(-5*u)*min(1,(duration-t)/.025)
        tone = math.sin(phase)+.22*math.sin(phase*2.01)*math.exp(-9*u)
        if chime:
            tone += .3*math.sin(TAU*base*1.5*t)*math.exp(-3*u)
        data.append((tone*(1-noise)+low*noise*3)*env)
    save(name,data)


def cue(name, notes, spacing):
    data = array('f',[0])*int((len(notes)*spacing+.6)*RATE)
    for k,midi in enumerate(notes):
        f = note(midi)
        for i in range(int(.6*RATE)):
            t = i/RATE
            env = min(1,t/.008)*math.exp(-9*t)*min(1,(.6-t)/.025)
            data[int(k*spacing*RATE)+i] += env*(math.sin(TAU*f*t)+.2*math.sin(TAU*f*2*t))
    save(name,data)


if __name__ == '__main__':
    score()
    for name,dur,freq,noise,chime,rise in [
        ('click',.09,660,.3,False,False),('coin',.23,1500,.08,True,False),
        ('hit',.24,115,.65,False,False),('hurt',.28,85,.55,False,False),
        ('tank',.32,145,.6,False,False),('assassin',.19,360,.85,False,False),
        ('mage',.44,530,.12,True,True),('marksman',.23,720,.7,False,False),
        ('support',.45,660,.1,True,True),('dash',.24,240,.95,False,True),
        ('shoot',.26,320,.75,False,False),('potion',.55,440,.22,True,True),
        ('error',.18,160,.2,False,False),('ultimate',.85,110,.45,True,False),
    ]:
        effect(name,dur,freq,noise,chime,rise)
    cue('levelup',[62,65,69,74],.10)
    cue('buy',[74,81],.09)
    cue('victory',[62,65,69,74,77,81],.17)
    cue('defeat',[62,60,57,50],.22)
    print('Generated original theme and 18 effects in', OUT)
