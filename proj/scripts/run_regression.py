#!/usr/bin/python

import argparse
import os
import pathlib
import time
import re
from random import randint

import run_test


class RegressionRunnerArguments:
    regression_name: str
    regressions_dir: str
    run_dir: str

parser = argparse.ArgumentParser(description="Spawn a batch of tests using a text-based regression list")

parser.add_argument("regression_name", type=str,
                    help="Specify the regression list to run")

parser.add_argument("regressions_dir", type=str, nargs="?",
                    default=os.environ["DV_REGRESSION_LISTS_DIR"],
                    help="Optionally specify where regression the lists are found (default to $DV_REGRESSION_LISTS_DIR) ")

parser.add_argument("run_dir", type=str, nargs="?",
                    default=os.environ["WORKDIR"] + "/regressions",
                    help="Optionally specify the base run directory (defaults to $WORKDIR/regressions)")



def create_regression_path(run_dir: str, regression_name: str) -> pathlib.Path:
    now: float = time.time()
    formatted_time_str = time.strftime("%Y-%m-%d--%H-%M-%S", time.localtime(now))

    regression_run_path = pathlib.Path(f"{run_dir}/{regression_name}--{formatted_time_str}")

    if regression_run_path.exists(): return regression_run_path

    regression_run_path.mkdir(parents=True)

    return regression_run_path



def parse_regression_file(regressions_dir: str, regression_name: str, regression_run_path: pathlib.Path) -> list[run_test.TestRunnerArguments]:
    regression_file_path = pathlib.Path(f"{regressions_dir}/{regression_name}")
    test_runner_parser = argparse.ArgumentParser()
    run_test.add_arguments_to_argument_parser(test_runner_parser)
    command_args: list[str]
    test_args: list[run_test.TestRunnerArguments] = []


    with regression_file_path.open("r", encoding="utf-8") as r:
        for line in r:
            line = re.sub(r"#.*$", r"", line)
            line = line.strip().lower()
            if line.isspace() or line == "":
                continue # Skip empty lines or lines that were only comments

            command_args = line.split()

            test_args.append(
                test_runner_parser.parse_args(
                    command_args,
                    namespace=run_test.TestRunnerArguments()
                )
            )

            test_args[-1].run_dir = str(regression_run_path)
            if test_args[-1].seed == None:
                test_args[-1].seed = randint(0, 4294967295)

    return test_args


def main() -> None:
    args: RegressionRunnerArguments
    regression_run_path: pathlib.Path
    tests_and_arguments_to_run: list[run_test.TestRunnerArguments]

    args = parser.parse_args(namespace=RegressionRunnerArguments())
    regression_run_path = create_regression_path(args.run_dir, args.regression_name)
    tests_and_arguments_to_run = parse_regression_file(args.regressions_dir, args.regression_name, regression_run_path)
    test_results: list[run_test.TestResult] = []

    summary_file_path: pathlib.Path = regression_run_path / "results.txt"
    result = run_test.TestResult

    with summary_file_path.open("w", encoding="utf-8") as s:
        for cmd in tests_and_arguments_to_run:
            print(f"Starting test {cmd.test_name}")
            result = run_test.run_test(cmd)
            test_results.append(result)
            print(f"{cmd.test_name} finished with {result} code")
            s.write(f"{cmd.test_name:<20}({cmd.seed:>10d}) : {result.name}\n")

    if all(r == run_test.TestResult.PASS for r in test_results):
        print("PASS")
    else:
        print("FAIL")


if __name__ == "__main__":
    main()
