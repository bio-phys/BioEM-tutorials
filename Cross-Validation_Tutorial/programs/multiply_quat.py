import math
import numpy as np

def q_mult(q1, q2):
    x1, y1, z1, w1 = q1
    x2, y2, z2, w2 = q2
    w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2
    x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2
    y = w1 * y2 + y1 * w2 + z1 * x2 - x1 * z2
    z = w1 * z2 + z1 * w2 + x1 * y2 - y1 * x2
    return x, y, z, w


file = open('base','r')
linesbase = file.readlines()
file.close()


#for ii in linesbase:

	#b0 = float(ii.split()[0])
	#b1 = float(ii.split()[1])
	#b2 = float(ii.split()[2])
	#b3 = float(ii.split()[3])
	#base = np.array([b0,b1,b2,b3])

file = open('./programs/smallGrid_125','r')
lines = file.readlines()
file.close()

v= [[0 for x in range(4)] for y in (range(len(linesbase)*125))] 

for ii in range(len(linesbase)):
    b0 = float(linesbase[ii].split()[0])
    b1 = float(linesbase[ii].split()[1])
    b2 = float(linesbase[ii].split()[2])
    b3 = float(linesbase[ii].split()[3])
    base = np.array([b0,b1,b2,b3])
    for i in range(125):

        q0t = float(lines[i].split()[0])
        q1t = float(lines[i].split()[1])
        q2t = float(lines[i].split()[2])
        q3t = float(lines[i].split()[3])
        dqt = np.array([q0t,q1t,q2t,q3t])
        v[ii*125+i] = q_mult(base,dqt)
	
np.savetxt("sampling",v)

