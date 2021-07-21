import os
import json
import click
import hashlib
from pathlib import Path
from loguru import logger
from rich.progress import track
from collections import defaultdict

valid_data_type = ("NUM", "TEXT", "DOUBLE")
bug_reports = Path("/data/liusong/Squirrel_DBMS/SQLite/second_unique_reports")
sqlite_binary = Path(
    "/data/liusong/sqlite2/bld/74e5a5a703ce07ab412ac28ea7a14cf93f59da33/sqlite3"
)
query_minimizer = Path("/data/liusong/Squirrel_DBMS/SQLite/query-minimizer")
fuzz_work_dir = Path("/data/liusong/Squirrel_DBMS/SQLite/fuzz_root")


@click.group()
def cli():
    """SQLite Query Minimizer CLI."""
    pass


@cli.group()
def eval():
    """Evaluate whether if provided query is false positive."""
    pass


@cli.command()
@click.argument("reports", type=click.Path(exists=True))
def dedup(reports):
    """De-duplicate query by md5sum."""
    reports = Path(reports)
    unique_reports = dict()
    all_report_files = [
        report
        for report in reports.rglob("*")
        # skip directory and files with suffix.
        if not report.is_dir() and report.suffix
    ]

    def md5sum(string):
        """Get the md5 hash value of string."""
        return hashlib.md5(string.encode("utf-8")).hexdigest()

    duplicate = defaultdict(list)
    for report in track(all_report_files):
        report_batch = report.parent.name

        with open(report) as f:
            content = f.readlines()
            # skip the first line(contains the report id)
            content = "\n".join(content[1:])

        md5 = md5sum(content)
        if md5 not in unique_reports:
            unique_reports[md5] = report
            continue

        duplicate[report].append(unique_reports[md5])

    for report, dup_reports in duplicate.items():
        logger.debug("[-] Report:\t{}".format(report))
        for r in dup_reports:
            logger.debug(" " * 4 + "Duplicate:\t{}".format(r))

    logger.info("Complete running deduplicate task for {}".format(reports))


@cli.command()
@click.argument("reports", type=click.Path(exists=True))
@click.option(
    "-m", "--parallel", is_flag=True, help="run the query minimizer in parallel."
)
def run(reports, parallel):
    """Run the query minimizer."""
    reports = Path(reports)
    json_bug_reports = [report for report in reports.rglob("*.json")]

    if parallel:
        logger.warning("Parallel mode current not support.")
    else:
        for report in track(json_bug_reports):
            command = (
                "{}".format(query_minimizer)
                + " -t 1000+ -m none "
                + " -i {} ".format(fuzz_work_dir / "inputs")
                + " -o {} ".format(fuzz_work_dir / "outputs")
                + " -O NOREC "
                + " -r {} ".format(report)
                + " -- {}".format(sqlite_binary)
            )
            os.system(cmd)

    logger.info("Complete running query minimizer for {}".format(reports))


@eval.command()
def view_affinity():
    """FP: view affinity."""
    count = 0
    notsure = 0

    def parse_table_query(create_table_queries):
        table_dict = {}
        for table_query in create_table_queries:
            table_name = table_query.split()[2]
            table_type = table_query.split()[5]

            # print(table_name, table_type)
            if table_type not in available_type:
                continue

            table_dict[table_name] = table_type

        return table_dict

    # unique_reports = [Path('unique_reports/report1/bug_1.json')]
    for file in unique_reports.rglob("*.json"):
        # for file in unique_reports:
        if file.is_dir():
            continue

        with open(file) as f:
            data = json.load(f)
        # print(file)

        database_query = data["database_query"].splitlines()
        oracle_query = data["first_oracle"]

        # print(database_query)

        create_table_queries = [
            line for line in database_query if line.startswith("CREATE TABLE ")
        ]
        create_view_query = [
            line
            for line in database_query
            if line.startswith("CREATE VIEW ")
            if "UNION" in line
        ]

        if not create_table_queries:
            continue

        # print(create_table_queries)
        table_dict = parse_table_query(create_table_queries)
        # print()

        for view_query in create_view_query:
            view_name = view_query.split()[2]
            query_before_union, query_after_union = view_query.split("UNION", 1)

            if "FROM" not in query_before_union or "FROM" not in query_after_union:
                continue

            first_table_name = query_before_union.split()[
                query_before_union.split().index("FROM") + 1
            ]
            second_table_name = query_after_union.split()[
                query_after_union.split().index("FROM") + 1
            ]

            if not first_table_name or not second_table_name:
                continue

            if first_table_name not in table_dict:
                print(
                    "[!] {} not in table dict: {}".format(
                        first_table_name, file.with_suffix("")
                    )
                )
                notsure += 1
                continue

            if second_table_name not in table_dict:
                print(
                    "[!] {} not in table dict: {}".format(
                        second_table_name, file.with_suffix("")
                    )
                )
                notsure += 1
                continue

            if (
                table_dict[first_table_name] != table_dict[second_table_name]
                and "FROM {}".format(view_name) in oracle_query
            ):
                analysis_report = file.with_suffix(".txt")
                print("[+] FP1:", file.with_suffix(""), "Reports:", analysis_report)

                f = open(analysis_report, "w")
                f.write("View collision(auto detected)\n\n")

                print("\t=> Table: ")
                f.write("=> Table: \n")
                for table_query in create_table_queries:
                    print("\t=>", table_query)
                    f.write(f"=> {table_query}\n")

                print()
                f.write("\n")
                print("\t=> View:")
                f.write("=> View:\n")
                print("\t=>", view_query)
                f.write(f"=> {view_query}\n")
                print()
                f.write("\n")

                print("\t=> Oracle:")
                f.write("=> Oracle:\n")
                print("\t=>", oracle_query)
                f.write(f"=> {oracle_query}\n")
                print()

                f.close()
                count += 1

                # dest = Path('fp1') / file.parent.name
                # os.system("mv {} {}".format(file, dest))

    print(f"Total: {count}, Not sure: {notsure}")


@eval.command()
def rtree_compare():
    """FP: create table using rtree and compare its member."""
    count = 0
    notsure = 0
    # unique_reports = [Path('unique_reports/report1/bug_1.json')]
    for file in unique_reports.rglob("*.json"):
        if file.is_dir():
            continue

        with open(file) as f:
            data = json.load(f)

        database_query = data["database_query"].splitlines()
        oracle_query = data["first_oracle"]

        rtree_table_query = [
            query
            for query in database_query
            if query.startswith("CREATE") and "rtree" in query
        ]

        if not rtree_table_query:
            continue

        rtree_table_query = rtree_table_query[0]

        rtree_table_name = rtree_table_query.split()[3]

        if not rtree_table_name.startswith("v"):
            print(
                "[!] {} is not a valid rtree table name: {}".format(
                    rtree_table_name, file.with_suffix("")
                )
            )
            notsure += 1
            continue

        if "FROM {}".format(rtree_table_name) not in oracle_query:
            print(
                "[!] {} not used in oracle query: {}".format(
                    rtree_table_name, file.with_suffix("")
                )
            )
            notsure += 1
            continue

        rtree_table_members = rtree_table_query[
            rtree_table_query.find("(") + 1 : rtree_table_query.find(")")
        ]
        rtree_table_members = [v.strip() for v in rtree_table_members.split(",")]

        analysis_report = file.with_suffix(".txt")
        print("[+] FP2:", file.with_suffix(""), "Reports:", analysis_report)
        f = open(analysis_report, "w")
        f.write("Compare rtree member with large number(auto detected)\n\n")

        print("\t=> rtree table:", rtree_table_name, "=> members:", rtree_table_members)
        f.write(f"=> rtree query: {rtree_table_query}\n")
        f.write(f"=> rtree table: {rtree_table_name}\n")
        f.write(f"=> members: {rtree_table_members}\n")

        f.write("\n")
        print("\t=>", oracle_query)
        f.write(f"=> Oracle:\n=> {oracle_query}\n")
        print()

        count += 1

    print(f"Total: {count}, Not sure: {notsure}")


if __name__ == "__main__":
    cli()
