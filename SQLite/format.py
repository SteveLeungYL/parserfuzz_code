import os


def format():
    """Format all code."""
    output = os.popen("find . -type f").read()

    file_paths = output.splitlines()
    python_file_paths = [f for f in file_paths if f.endswith(".py")]
    cpp_file_paths = [f for f in file_paths if f.endswith(".cpp") or f.endswith(".h")]

    for file_path in python_file_paths:
        os.system("black " + file_path)

    for file_path in cpp_file_paths:
        os.system("clang-format -i " + file_path)


if __name__ == "__main__":
    format()
