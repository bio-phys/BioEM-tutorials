import numpy as np 
import sys

logp1=np.loadtxt(sys.argv[1])
logp2=np.loadtxt(sys.argv[2])

p1=1/(1+np.exp(logp2-logp1))
p2=1/(1+np.exp(logp1-logp2))

def kld(p1,p2):
    if len(p1)==len(p2):
        return(0.5*np.dot(p1,np.log(p1/p2)))

#Shannon Entropy
def shan_entro(p):
    return(-1.0*np.dot(p,np.log(p)))

#Normalized Jansen-Shannon divergence
def njsd(p1,p2):
    M=.5*(p1+p2)
    return( (kld(p1,M)+kld(p2,M))/np.sqrt(shan_entro(p1)*shan_entro(p2)))

print("%.10f" % njsd(p1,p2))
