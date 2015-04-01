# Python script to parse output of mongostat command

import sys
import re
import numpy

infile = sys.argv [1]
outfile = sys.argv [2]

headers = []

####################
try:
    inf = open (infile, 'r')
    outf = open (outfile, 'w')

    data = []
    lineCount = 0
    numDataRows = 0
    numHeaders = 0
    numHrStarts = 0
    begin = False
    hrId = 0
    hourlyData = []
    for line in inf.readlines ():

        line = line.replace ('idx miss %', 'idx_miss_%')
        line = line.replace ('locked db', 'locked_db')
        line = line.replace ('*', '')

        # break up line at whitespaces
        tokens = line.split ();
        
        # get column names (headers); only once
        if tokens [0] == "insert" and headers == []:
            headers = tokens
            print line
            print lineCount, "> Headers: " , headers

            # get number of columns (headers)
            numHeaders = len (headers)
            
            # add empty lists for each headder
            for h in range (len (headers)):
                data.append (0);

        if tokens [0] != "insert" and lineCount > 1:
            hr = tokens [numHeaders - 1]
            timetk = hr.split (':')
            #print timetk
            if (timetk [1] == '00' and timetk [2] == '00'):
                numHrStarts += 1
                if (numHrStarts == 1):
                    begin = True
                else:
                    hrId += 1
                    nInserts = data [0]
                    nQuery = data [1]
                    nUpdates = data [2]
                    nDeletes = data [3]
                    tmpArray = []

                    #tmpArray.append (hrId)
                    tmpArray.append (hr)
                    tmpArray.append (nInserts)
                    tmpArray.append (nQuery)
                    tmpArray.append (nUpdates)
                    tmpArray.append (nDeletes)

                    # add array to global list of hourly data
                    hourlyData.append (tmpArray)

                    for h in range (len (headers)):
                        data [h] = 0
                
            if (begin):
                #print line
                numDataRows += 1

                '''
                for i in range (len (tokens)):
                    item = re.sub ('[*]', '', tokens [i])
                    data [i].append (item)
                '''
                data [0] += int (tokens [0])
                data [1] += int (tokens [1])
                data [2] += int (tokens [2])
                data [3] += int (tokens [3])
                
        lineCount += 1

    '''
    for i in range (len (data [numHeaders - 1])):
        print data [numHeaders - 1][i]
    '''
    #print data [numHeaders - 1][0], "\t", data [numHeaders - 1][ len (data [numHeaders - 1]) - 1]
    #print data
    print('\n'.join('{}: {}'.format(*k) for k in enumerate(hourlyData)))
    for h in range (len (hourlyData)):
        outf.write (','.join (str(x) for x in hourlyData [h]))
        outf.write ('\n')

    #print hourlyData
    print "num data rows: ", numDataRows
    #print data [numHeaders - 1]
####################
finally:
    inf.close ()
    outf.close ()
