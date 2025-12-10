#!/usr/bin/env python3
import sys
import subprocess
from pathlib import Path

def run_assembler(asm_path: str, out_path: str | None = None) -> None:

    here = Path(__file__).resolve().parent
    assemble_py = here / "assemble.py"
    instr_csv   = here / "instructions.csv"

    if not assemble_py.exists():
        print(f"Error: {assemble_py} not found.")
        sys.exit(1)

    cmd = [sys.executable, str(assemble_py)]

    # Use your custom instruction + register files automatically
    if instr_csv.exists():
        cmd += ["-i", str(instr_csv)]

    if out_path is not None:
        # Make sure it ends with .mem
        out_path = str(out_path)
        if not out_path.endswith(".mem"):
            out_path += ".mem"
        cmd += ["-o", out_path]

    cmd.append(asm_path)

    print("Running:", " ".join(cmd))
    result = subprocess.run(cmd)

    if result.returncode == 0:
        print("✅ Assembling succeeded.")
        if out_path is None:
            # assemble.py default output name
            default_out = Path(asm_path).with_suffix(".mem")
            print(f"Output written to: {default_out}")
        else:
            print(f"Output written to: {out_path}")
    else:
        print("❌ Assembling failed. Check the error message above.")


def main():
    # If user gave the asm file as a command-line argument, use that.
    # Otherwise, ask interactively.
    if len(sys.argv) > 1:
        asm_file = sys.argv[1]
    else:
        asm_file = input("Enter the path to your assembly file (.s): ").strip()

    if not asm_file:
        print("No assembly file provided.")
        sys.exit(1)

    # Optional second arg: output file
    out_file = None
    if len(sys.argv) > 2:
        out_file = sys.argv[2]
    else:
        # Ask user if they want a custom output name
        ans = input("Custom output .mem filename? (leave blank for default): ").strip()
        if ans:
            out_file = ans

    run_assembler(asm_file, out_file)


if __name__ == "__main__":
    main()
