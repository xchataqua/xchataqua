#!/usr/bin/python
import re
import sys
import polib
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


def create_strings_map(s):
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


def create_po_map(s):
    m = {}
    for i in s:
        if not i.msgid:
            continue
        k, v = i.msgid, i.msgstr
        k, v = deshortcut(k, v)
        m[k] = v
        if k.startswith('XChat: '):
            m[k.lstrip('XChat: ')] = v.lstrip('XChat: ')
    return m


def apply(source, *trans_maps):
    result = []
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
        trans = None
        for m in trans_maps:
            trans = m.get(orig)
            if trans:
                break
        item = l.copy()
        if trans:
            item['value'] = prefix + trans + suffix
        result.append(item)
    return result


def load_source(filename):
    if filename.endswith('.po'):
        l = polib.pofile(filename)
        m = create_po_map(l)
    elif filename.endswith('.strings'):
        l = localizable.parse_strings(filename=filename)
        m = create_strings_map(l)
    else:
        assert False, filename
    return l, m

if __name__ == '__main__':
    f1 = sys.argv[1]
    f2 = sys.argv[2]
    f3 = sys.argv[3]

    s = localizable.parse_strings(filename=f1)
    l1, m1 = load_source(f2)
    l2, m2 = load_source(f3)

    r = apply(s, m1, m2)
    print(localizable.write_strings(r).encode('utf-8'))
