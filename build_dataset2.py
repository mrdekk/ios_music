import mido
import json
import os
import sys
import pickle
import numpy as np

from collections import defaultdict

instruments = [73, 74, 75, 76, 77, 78, 79, 80]

def process(filename):
    global instruments

    events = []

    f = mido.MidiFile(filename)
    for track in f.tracks:

        workChannel = -1

        currentNote = -1
        offset = -1
        duration = -1
        velocity = -1

        for msg in track:

            if msg.type == "program_change":
                if msg.program in instruments:
                    workChannel = msg.channel
                    print ("Flute channel set to %d\n" % workChannel)

            elif msg.type == "note_on":
                if workChannel >= 0:
                    if msg.velocity > 0:
                        currentNote = msg.note
                        offset = msg.time
                        velocity = msg.velocity
                    else:
                        if currentNote != -1 and offset != -1 and velocity != -1:
                            duration = msg.time
                            events.append((currentNote, offset, duration, velocity))

                        currentNote = -1
                        offset = -1
                        duration = -1
                        velocity = -1

            elif msg.type == "note_off":
                if currentNote != -1 and offset != -1 and velocity != -1:
                    duration = msg.time
                    events.append((currentNote, offset, duration, velocity))

                currentNote = -1
                offset = -1
                duration = -1
                velocity = -1

        if workChannel >= 0:
            global midiEvents
            midiEvents += events

midiEvents = []

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
                #raise

            # to prevent waiting for whole dataset
            #if fileCount > 5:
            #    break

print("Step 1. Finished! Processed %d files, %d MIDI events" % (fileCount, len(midiEvents)))

notes = defaultdict(int)
offsets = defaultdict(int)
durations = defaultdict(int)
velocities = defaultdict(int)

for event in midiEvents:
    notes[event[0]] += 1
    offsets[event[1]] += 1
    durations[event[2]] += 1
    velocities[event[3]] += 1

print ("Notes: %s\n" % notes.keys())
print ("Offsets: %s\n" % offsets.keys())
print ("Durations: %s\n" % durations.keys())
print ("Velocities: %s\n" % velocities.keys())

uniqNotes = len(notes)
uniqOffsets = len(offsets)
uniqDurations = len(durations)
uniqVelocities = len(velocities)
print("Step 2. Unique notes %d, offsets %d, durations %d, velocities %d, total = %d" % (uniqNotes, uniqOffsets, uniqDurations, uniqVelocities, uniqNotes + uniqOffsets + uniqDurations + uniqVelocities))

notesKeys = sorted(notes.keys())
notesEncoded = { n:i for i,n in enumerate(notesKeys)}

offsetsKeys = sorted(offsets.keys())
offsetsEncoded = { o:i for i,o in enumerate(offsetsKeys)}

durationsKeys = sorted(durations.keys())
durationsEncoded = { d:i for i,d in enumerate(durationsKeys)}

velocitiesKeys = sorted(velocities.keys())
velocitiesEncoded = { v:i for i,v in enumerate(velocitiesKeys)}

pickle.dump(notesKeys, open("g2.notes.p", "wb"))
pickle.dump(offsetsKeys, open("g2.offsets.p", "wb"))
pickle.dump(durationsKeys, open("g2.durations.p", "wb"))
pickle.dump(velocitiesKeys, open("g2.velocities.p", "wb"))

print("Step 3. One Hot encoding completed!")

X = np.zeros((len(midiEvents), uniqNotes + uniqOffsets + uniqDurations + uniqVelocities), dtype=np.float32)
print("Step 4. Training file shape:", X.shape)

for i, (note, offset, duration, velocity) in enumerate(midiEvents):
    noteOneHot = np.zeros(uniqNotes)
    noteOneHot[notesEncoded[note]] = 1.0
    X[i, 0:uniqNotes] = noteOneHot

    offsetOneHot = np.zeros(uniqOffsets)
    offsetOneHot[offsetsEncoded[offset]] = 1.0
    X[i, uniqNotes:uniqNotes + uniqOffsets] = offsetOneHot

    durationOneHot = np.zeros(uniqDurations)
    durationOneHot[durationsEncoded[duration]] = 1.0
    X[i, uniqNotes + uniqOffsets:uniqNotes + uniqOffsets + uniqDurations] = durationOneHot

    velocityOneHot = np.zeros(uniqVelocities)
    velocityOneHot[velocitiesEncoded[velocity]] = 1.0
    X[i, uniqNotes + uniqOffsets + uniqDurations:] = velocityOneHot

np.save("g2.X.npy", X)
