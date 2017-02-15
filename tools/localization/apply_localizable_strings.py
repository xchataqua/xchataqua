#!/usr/bin/python
import re
import sys
import localizable


def _deshort(s):
    if s.endswith('...'):
        s = s.rstrip('...')
    if s.endswith(':'):
        s = s.rstrip(':')
    s = re.sub(r'_([A-Z])', r'\1', s)
    return s


def deshortcut(k, v):
    k2 = _deshort(k)
    if k != k2:
        v = _deshort(v)
        v = re.sub(r'\([A-Z]\)', '', v)
    return k2, v


def create_map(s):
    m = {}
    for i in s:
        if not i['key']:
            continue
        k, v = i['key'], i['value']
        k, v = deshortcut(k, v)
        m[k] = v
        if k.startswith('XChat: '):
            m[k.lstrip('XChat: ')] = v.lstrip('XChat: ')
    return m


def apply(source, localization):
    trans_map = create_map(localization)
    for l in source:
        orig = l['value']
        prefix = u''
        suffix = u''
        if orig.endswith('...'):
            suffix = u'...'
            orig = orig.rstrip('...')
        elif orig.endswith(':'):
            suffix = u':'
            orig = orig.rstrip(':')
        trans = trans_map.get(orig)
        if trans:
            l['value'] = prefix + trans + suffix


if __name__ == '__main__':
    f1 = sys.argv[1]
    f2 = sys.argv[2]

    s = localizable.parse_strings(filename=f1)
    l = localizable.parse_strings(filename=f2)

    apply(s, l)

    print(localizable.write_strings(s).encode('utf-8'))