import os
import sys
import getopt
import sqlite3
import json


def print_usage():
    print "Usage: $ python build_procedure_jsons.py -d <sqlitedb>"
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


def percent_reduction(a, b):
    return (a-b)/a * 100


def write_json_files(rows, type):
    info_objs = {}
    for r in rows:
        procedure_id = r[0]
        hrr_id = r[1]
        avg_charge = r[2]
        avg_pmt = r[3]

        if not procedure_id in info_objs:
            info_objs[procedure_id] = {}

        info_objs[procedure_id][hrr_id] = {
                'chrg': avg_charge,
                'pmt': avg_pmt,
                'reduct': percent_reduction(avg_charge, avg_pmt)
            }

    for procedure_id, drg_obj in info_objs.iteritems():
        with open('../data/' + type + '_' + str(procedure_id) +'_hrr.json', 'w') as out:
            json.dump(drg_obj, out)

    return


if __name__ == '__main__':

    db_name = get_db_name()

    if not os.path.isfile(db_name):
        print "Database not found."
        sys.exit(2)
   
    with sqlite3.connect(db_name) as conn:
        cur = conn.cursor()

        #First get the averages for the DRGs
        cur.execute("""
            select
              p.procedure_id as procedure_id,
              zip_regions.hrr_id as hrr_id,
              avg(p.avg_charge) as avg_charge,
              avg(p.avg_payment) as avg_payment
            from inpatient_payment_info p
            left join providers on providers.id = p.provider_id
            left join zip_regions on providers.zip = zip_regions.zip
            where zip_regions.hrr_id is not null
            group by zip_regions.hrr_id, p.procedure_id
            order by p.procedure_id
            """)

        rows = cur.fetchall()
        write_json_files(rows, 'drg')

        # Do the same for the APCs
        cur.execute("""
            select
              p.procedure_id as procedure_id,
              zip_regions.hrr_id as hrr_id,
              avg(p.avg_charge) as avg_charge,
              avg(p.avg_payment) as avg_payment
            from outpatient_payment_info p
            left join providers on providers.id = p.provider_id
            left join zip_regions on providers.zip = zip_regions.zip
            where zip_regions.hrr_id is not null
            group by zip_regions.hrr_id, p.procedure_id
            order by p.procedure_id
            """)

        rows = cur.fetchall()
        write_json_files(rows, 'apc')
