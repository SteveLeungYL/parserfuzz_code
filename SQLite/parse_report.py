import os
import click
import json
from pathlib import Path


class OracleQuery(object):
    def __init__(self, query: str, result: str = ""):
        self.query = query.strip()
        self.result = result


class OracleQueryGroup(object):
    def __init__(self, first: OracleQuery, second: OracleQuery):
        self.first = first
        self.second = second

    @property
    def is_different_result(self):
        if self.first.result.startswith("Error") and self.second.result.startswith(
            "Error"
        ):
            return False

        return float(self.first.result) != float(self.second.result)


class MinimizeTarget(object):
    def __init__(self, database_query: str, oracle_queries: OracleQueryGroup):
        self.database_query = database_query
        self.oracle_queries = oracle_queries

    @property
    def first_oracle(self):
        return self.oracle_queries.first.query

    @property
    def first_query(self):
        return self.database_query + "\n" + self.first_oracle

    @property
    def first_result(self):
        return self.oracle_queries.first.result

    @property
    def second_oracle(self):
        return self.oracle_queries.second.query

    @property
    def second_query(self):
        return self.database_query + "\n" + self.second_oracle

    @property
    def second_result(self):
        return self.oracle_queries.second.result

    @property
    def is_different_result(self):
        return self.oracle_queries.is_different_result

    def dumps(self):
        obj = {
            "database_query": self.database_query,
            "first_result": self.first_result,
            "second_result": self.second_result,
            "first_oracle": self.first_oracle,
            "second_oracle": self.second_oracle,
        }
        return json.dumps(obj, indent=2)


@click.command()
@click.argument("report", type=click.Path(exists=True))
@click.option(
    "-o",
    "--output",
    help="output directory.",
    default="simplified_reports",
    type=click.Path(),
)
def parse(report, output):

    with open(report) as f:
        contents = f.read()

    complete_query = contents[
        contents.find("Query:") + len("Query:") : contents.find("Result string:")
    ]
    complete_query = complete_query.strip()

    database_query = complete_query[: complete_query.find("SELECT 'BEGIN VERI 0';")]
    database_query = "\n".join(query.strip() for query in database_query.splitlines())

    oracle_query_group = complete_query[complete_query.find("SELECT 'BEGIN VERI 0';") :]
    oracle_query_group = oracle_query_group.splitlines()

    result_string = contents[
        contents.find("Result string:")
        + len("Result string:") : contents.find("Final_res:")
    ]
    # remove error message of database query.
    result_string = result_string[result_string.find("BEGIN VERI 0") :]
    result_string = result_string.strip().splitlines()

    oracle_queries = []
    i = 0
    while i < len(oracle_query_group):
        if "SELECT 'BEGIN VERI 0'" in oracle_query_group[i]:
            first_oracle_result = result_string[i + 1].strip()
            first_oracle_query = OracleQuery(
                oracle_query_group[i + 1].strip(), first_oracle_result
            )

            second_oracle_result = result_string[i + 4].strip()
            second_oracle_query = OracleQuery(
                oracle_query_group[i + 4].strip(), second_oracle_result
            )

            oracle_group = OracleQueryGroup(first_oracle_query, second_oracle_query)
            oracle_queries.append(oracle_group)
            i += 5

        i += 1

    minimize_targets = [
        MinimizeTarget(database_query, oq)
        for oq in oracle_queries
        if oq.is_different_result
    ]

    if not os.path.exists(output):
        os.mkdir(output)

    for idx, target in enumerate(minimize_targets):
        print(
            "first {} <=> second {}".format(target.first_result, target.second_result)
        )

        print()

        print("first query:")
        print(target.first_query)

        print()

        print("second query:")
        print(target.second_query)

        print()

        with open(os.path.join(output, str(idx + 1) + ".json"), "w") as f:
            f.write(target.dumps())

    print("Total {} oracle queries.".format(len(minimize_targets)))


if __name__ == "__main__":
    parse()
