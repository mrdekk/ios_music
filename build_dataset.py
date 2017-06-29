import mido
import json
import os
import sys
import pickle
import numpy as np

from collections import defaultdict

instruments = [73, 74, 75, 76, 77, 78, 79, 80]

def process(filename):
    global ticksUntilNextTrack
    global instruments
    global notes
    global notesTicks
    global notesVelocities

    extraTicks = 0

    events = []

    f = mido.MidiFile(filename)
    for track in f.tracks:
        totalTicks = 0
        workChannel = -1
        for msg in track:
            totalTicks += msg.time

            if msg.type == "program_change":
                if msg.program in instruments:
                    workChannel = msg.channel
                    extraTicks += msg.time

            elif msg.type == "note_on":
                if workChannel >= 0:
                    ticks = msg.time

                    if len(events) == 0:
                        ticks += ticksUntilNextTrack
                        ticksUntilNextTrack = 0

                    ticks += extraTicks
                    extraTicks = 0
                    lastTicks = totalTicks

                    notes[msg.note] += 1
                    notesTicks[ticks] += 1
                    notesVelocities[msg.velocity] += 1

                    events.append((msg.note, ticks, msg.velocity))

            else:
                if workChannel >= 0:
                    extraTicks += msg.time

        if workChannel >= 0:
            global midiEvents
            midiEvents += events
            ticksUntilNextTrack = 480 - (lastTicks % 480)

midiEvents = []
ticksUntilNextTrack = 0

notes = defaultdict(int)
notesTicks = defaultdict(int)
notesVelocities = defaultdict(int)

fileCount = 0
for root, directories, filenames in os.walk("midi"):
    for filename in filenames:
        if filename.endswith(".mid") or filename.endswith(".midi"):
            print("Step 1. Processing %s..." % (filename))
            try:
                process(os.path.join(root, filename))
                fileCount += 1
                print("Step 1. Processed %s! (total = %d)" % (filename, fileCount))
            except KeyboardInterrupt:
                raise
            except:
                e = sys.exc_info()[0]
                print("Step 1. Fail to process %s! %s" % (filename, e))

            # to prevent waiting for whole dataset
            #if fileCount > 5:
            #    break

print("Step 1. Finished! Processed %d files, %d MIDI events" % (fileCount, len(midiEvents)))


uniqNotes = len(notes)
uniqTicks = len(notesTicks)
uniqVelocities = len(notesVelocities)
print("Step 2. Unique notes %d, ticks %d, velocities %d" % (uniqNotes, uniqTicks, uniqVelocities))

notesKeys = sorted(notes.keys())
notesOneHot = { n:i for i,n in enumerate(notesKeys)}

ticksKeys = sorted(notesTicks.keys())
ticksOneHot = { n:i for i,n in enumerate(ticksKeys)}

velocitiesKeys = sorted(notesVelocities.keys())
velocitiesOnHot = { n:i for i,n in enumerate(velocitiesKeys)}

pickle.dump(notesKeys, open("notes.p", "wb"))
pickle.dump(ticksKeys, open("ticks.p", "wb"))
pickle.dump(velocitiesKeys, open("velocities.p", "wb"))
print("Step 3. One Hot encoding completed!")

X = np.zeros((len(midiEvents), uniqNotes + uniqTicks + uniqVelocities), dtype=np.float32)
print("Step 4. Training file shape:", X.shape)

for i, (note, ticks, velocity) in enumerate(midiEvents):
    noteOnHot = np.zeros(uniqNotes)
    noteOnHot[notesOneHot[note]] = 1.0
    X[i, 0:uniqNotes] = noteOnHot

    tickOneHot = np.zeros(uniqTicks)
    tickOneHot[ticksOneHot[ticks]] = 1.0
    X[i, uniqNotes:uniqNotes + uniqTicks] = tickOneHot

    velocityOnHot = np.zeros(uniqVelocities)
    velocityOnHot[velocitiesOnHot[velocity]] = 1.0
    X[i, uniqNotes+uniqTicks:] = velocityOnHot

np.save("X.npy", X)
