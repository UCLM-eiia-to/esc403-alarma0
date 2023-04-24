#!/usr/bin/python

import sys, traceback, os, os.path
try:
    import lxml.etree as ET
except:
    print('Install lxml python package with:\npython -m pip install lxml')

dirname = os.path.dirname(os.path.abspath(__file__))

xslf = dirname+'/pt2cpp.xsl'
print(f'XSL: {xslf}')
xslt = ET.parse(xslf)
for f in sys.argv[1:]:
    print(f'Transformando {f}', end='')

    try:
        dom = ET.parse(f)
        transform = ET.XSLT(xslt)
        newdom = transform(dom)
    except:
        print('FAIL')
        traceback.print_exc()

    srcdir = os.path.dirname(os.path.abspath(os.path.dirname(f)))
    basename = os.path.splitext(os.path.basename(f))[0]
    outdir = f'{srcdir}/generated'
    outf = f'{outdir}/{basename}.hh'
    print(f' -> {outf}', end='')
    if not os.path.exists(outdir): os.mkdir(outdir)
    try:
        with open(outf, 'wb') as out:
            newdom.write_output(out)
        print(' OK')
    except:
        print('FAIL')
        traceback.print_exc()
