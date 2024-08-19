#!/usr/bin/python

import argparse
from random import randint
import subprocess
import pathlib
import os
import sys
import re

class Args:
    test_name: str
    run_dir: str
    build_dir: str
    seed: int
    uvm_verbosity: str
    print_stdout: bool
    highlight_stdout: bool

parser = argparse.ArgumentParser(description="Run a UVM test using Vivado xsim")

parser.add_argument("test_name", type=str,
                    help="Specify the UVM test to run")

parser.add_argument("run_dir", type=str, nargs="?",
                    default=os.environ["WORKDIR"] + "/runs",
                    help="Optionally specify the base run directory (defaults to work dir)")

parser.add_argument("build_dir", type=str, nargs="?",
                    default=os.environ["WORKDIR"],
                    help="Optionally specify where to find the built project (defaults to work dir)")

parser.add_argument("--seed", type=int,
                    help="Specify the simulation seed")

parser.add_argument("--uvm_verbosity", type=str, default="UVM_LOW",
                    help="Specify the UVM_VERBOSITY level")

parser.add_argument("--print", action='store_true', dest="print_stdout",
                    help="Print output to STDOUT")

parser.add_argument("--highlight", action='store_true', dest="highlight_stdout", default=True,
                    help="Apply highlighting to keywords on stdout (pair with --print)")


class bcolors:
    OKBLUE = '\033[01;94m'
    OKCYAN = '\033[01;96m'
    OKGREEN = '\033[01;92m'
    WARNING = '\033[01;93m'
    FAIL = '\033[01;91m'
    ENDC = '\033[0m'



def print_test_output(test_output: str, highlight: bool) -> None:
    test_output = re.sub(r"(UVM_INFO)", rf"{bcolors.OKCYAN}\1{bcolors.ENDC}", test_output, flags=re.IGNORECASE)
    test_output = re.sub(r"(UVM_WARNING)", rf"{bcolors.WARNING}\1{bcolors.ENDC}", test_output, flags=re.IGNORECASE)
    test_output = re.sub(r"(UVM_ERROR|UVM_FATAL)", rf"{bcolors.FAIL}\1{bcolors.ENDC}", test_output, flags=re.IGNORECASE)

    test_output = re.sub(r"((?:TEST\s+)?PASSED)", rf"{bcolors.OKGREEN}\1{bcolors.ENDC}", test_output)
    test_output = re.sub(r"((?:TEST\s+)?FAILED)", rf"{bcolors.FAIL}\1{bcolors.ENDC}", test_output)

    sys.stdout.write(test_output)



def create_test_run_directory(build_dir: str, run_dir: str, test_name: str, seed: int) -> pathlib.Path:
    test_path = pathlib.Path(f"{run_dir}/{test_name}_{seed}")
    build_path = pathlib.Path(build_dir)

    if test_path.exists(): return test_path

    test_path.mkdir(parents=True)

    (test_path / pathlib.Path("xsim.dir")).symlink_to(
        (build_path / pathlib.Path("xsim.dir")), target_is_directory=True
    )

    for so_binary in build_path.glob("*.so"):
        (test_path / so_binary.name).symlink_to(so_binary)

    return test_path



def run_test(test_path: pathlib.Path, seed: int, test_name: str, uvm_verbosity: str, print_stdout: bool, highlight_stdout: bool):
    output_path: pathlib.Path

    output_path = test_path / "output.txt"

    os.chdir(f"{test_path}")
    print(os.getcwd())
    cmd = [
        "xsim",
        "tb_top_snapshot",
        "--tclbatch",  f"{os.environ['PROJECT_ROOT']}/xsim_cfg.tcl",
        "--sv_seed", f"{seed}",
        "--testplusarg", f"UVM_TESTNAME={test_name}",
        "--testplusarg", f"UVM_VERBOSITY={uvm_verbosity}"
    ]

    with output_path.open("w", encoding="utf-8") as f:
        f.write("RUN COMMAND: " + " ".join(cmd))
        process = subprocess.Popen(" ".join(cmd), shell=True, stdout=subprocess.PIPE)

        for line in iter(process.stdout.readline, b""):
            f.write(line.decode("utf-8"))
            if print_stdout:
                print_test_output(line.decode("utf-8"), highlight_stdout)

    print(f"Process finished with a {process.poll()} return code")

    return


def determine_test_pass_fail(test_path: pathlib.Path) -> None:
    output_path: pathlib.Path
    fail_count: int
    pass_string_found: bool
    fail_string_found: bool

    output_path = test_path / "output.txt"

    fail_count = 0
    pass_string_found = False
    fail_string_found = False

    with output_path.open("r", encoding="utf-8") as output_file:
        for line in output_file:
            if re.search(r"uvm_(?:error|fatal)\s+(?!:)", line, re.IGNORECASE):
                fail_count += 1

            if re.search(r"TEST PASSED", line):
                pass_string_found = True

            if re.search(r"TEST FAILED", line):
                fail_string_found = True

    if (fail_count == 0) and (pass_string_found) and (not fail_string_found):
        print("Test passed! :)")
    else:
        print(f"Test failed\n{fail_count} errors/fatals detected")






def main() -> None:
    args: Args
    test_path: pathlib.Path
    seed: int

    args = parser.parse_args(namespace=Args())
    seed = args.seed if args.seed != None else randint(0, 4294967295)
    test_path = create_test_run_directory(args.build_dir, args.run_dir, args.test_name, seed)
    run_test(test_path, seed, args.test_name, args.uvm_verbosity, args.print_stdout, args.highlight_stdout)
    determine_test_pass_fail(test_path)

    return



if __name__ == "__main__":
    main()