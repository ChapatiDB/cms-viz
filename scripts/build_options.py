import os
import sys
import getopt
import sqlite3

def print_usage():
    print "Usage: $ python build_options.py -d <sqlitedb>"
    sys.exit(2)


def get_db_name():
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'd:')
    except getopt.GetoptError:
        print_usage()

    for opt, arg in opts:
        if opt == '-d':
            return arg

    print_usage()


def escape(s):
    htmlCodes = (
        ("'", '&#39;'),
        ('"', '&quot;'),
        ('>', '&gt;'),
        ('<', '&lt;'),
        ('&', '&amp;')
    )

    for code in htmlCodes:
        s = s.replace(code[0], code[1])
    return s


if __name__ == '__main__':

    db_name = get_db_name()

    if not os.path.isfile(db_name):
        print "Database not found."
        sys.exit(2)
    
    with sqlite3.connect(db_name) as conn:
        cur = conn.cursor()

        cur.execute("""
            select id, name from drgs
            """)

        rows = cur.fetchall()

        for r in rows:
            print "<option value='%d'>%d - %s</option>" \
                % (r[0], r[0], escape(r[1]))
        

        print "---------------------------"

        cur.execute("""
            select id, name from apcs
            """)

        rows = cur.fetchall()

        for r in rows:
            print "<option value='%d'>%d - %s</option>" \
                % (r[0], r[0], escape(r[1]))
