#!/home/ssharma/anaconda2/bin/python
# -*- coding: utf-8 -*-
#First use mindis.sh
import networkx 
from networkx.algorithms.components.connected import connected_components
import sys
import string


numCh=48
ch=list(string.ascii_uppercase)+list(string.ascii_lowercase)
ch=ch[:numCh]

rawfile='pairs-'+str(sys.argv[1])+'.txt'
numfile='num-'+str(sys.argv[1])+'.txt'

fobj = open(rawfile, 'w')
fnum = open(numfile, 'w')


def to_graph(l):
    G = networkx.Graph()
    for part in l:
        # each sublist is a bunch of nodes
        G.add_nodes_from(part)
        # it also imlies a number of edges:
        G.add_edges_from(to_edges(part))
    return G

def to_edges(l):
    """ 
        treat `l` as a Graph and returns it's edges 
        to_edges(['a','b','c','d']) -> [(a,b), (b,c),(c,d)]
    """
    it = iter(l)
    last = next(it)

    for current in it:
        yield last, current
        last = current    

infile='contacts-'+str(sys.argv[1])+'.xvg'
with open(infile) as f:
    for line in f:
        line=line.rstrip('\n')
        line=line.split(';')
#        line = map(int, line)
#creat lists of line list
        c=[]
        for i in range(len(line)):
            l=line[i].split()
            l=map(int, l)
            c.append(l)
#replace by chian names
        for i, j in enumerate(c):
            for k,l in enumerate(j):
                if l > 0 :
                    c[i][k]=ch[i+k]
            c[i]=[m for m in c[i] if m != 0]
#           print c
        G = to_graph(c)
        G_out=list(connected_components(G))
#        fnum.write(str(len(G_out))+'\n')
        for r in range(len(G_out)):
#            fobj.write(str(list(G_out[r]))+' ; ')
            fobj.write(str(len(G_out[r]))+' ')
        fobj.write('\n')    
fobj.close()
fnum.close()
