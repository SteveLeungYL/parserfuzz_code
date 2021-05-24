import os
from pathlib import Path
from datetime import datetime

# edit cron job: `crontab -e`
# */30 * * * * python3 /path/to/exp_recorder.py >> /path/to/record.log

now = datetime.utcnow().strftime("%m%d-%H%M")
result_dir = Path('/home/sqlite/sqlite_results') / now
result_dir.mkdir(parents=True, exist_ok=True)

for fuzz_root_int in Path('SQLite').glob('fuzz_root_*'):
    fuzzer_stats = fuzz_root_int / "fuzzer_stats"
    bug_stats = fuzz_root_int / "bug_stats"
    
    dest_dir = result_dir / fuzz_root_int.name 
    if not dest_dir.exists():
        dest_dir.mkdir()

    command = f"cp {fuzzer_stats} {bug_stats} {dest_dir}"
    os.system(command)

print(f"Save experiment stats files at {now}")