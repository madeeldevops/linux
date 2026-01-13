# OVPN Test Scripts

This folder contains scripts to automate testing of `.ovpn` OpenVPN configurations using Linux Containers (LXC). It provides a framework to launch LXCs, distribute `.ovpn` files, run tests, fetch logs, and optionally clean up the containers after testing.

---

## Folder Structure

```text
bash/ovpn-test-scripts/
├── README.md
├── scripts/        # All test scripts
│   ├── run-all.sh
│   ├── launch-lxcs.sh
│   ├── start-tests.sh
│   ├── test.sh
│   ├── fetch-logs.sh
│   └── destroy-lxcs.sh
├── ovpn-files/     # Place all .ovpn client configs here
└── logs/           # Logs will be saved here after tests
```

---

## Requirements

- Linux host with [LXD/LXC](https://linuxcontainers.org/) installed and configured.
- `bash`, `jq`, `curl`, and `openvpn` installed (used inside the LXC template).
- `.ovpn` configuration files stored in `ovpn-files/` (beside `scripts/` folder).

---

## Usage

### 1. Run all tests (recommended)
```bash
cd bash/ovpn-test-scripts/scripts
./run-all.sh [NUM_LXCS]
```
- `NUM_LXCS` (optional, default `3`) — number of LXC test instances to launch.

The script will:

1. Launch LXCs using a base template (creates if missing)  
2. Start the tests across all `.ovpn` files in `../ovpn-files/` using round-robin distribution  
3. Fetch logs and merge them into `../logs/`  
4. Prompt to destroy LXCs when finished  

---

### 2. Launch LXCs only
```bash
./launch-lxcs.sh [NUM_LXCS] [PREFIX]
```
- `NUM_LXCS` — number of containers (default `3`)  
- `PREFIX` — container name prefix (default: `ovpn-test`)  

---

### 3. Start tests only
```bash
./start-tests.sh [PREFIX] [OVPN_DIR] [TEST_SCRIPT]
```
- `PREFIX` — LXC prefix (default: `ovpn-test-`)  
- `OVPN_DIR` — directory containing `.ovpn` files (default: `../ovpn-files`)  
- `TEST_SCRIPT` — script to run inside LXC (default: `./test.sh`)  

---

### 4. Fetch logs only
```bash
./fetch-logs.sh [PREFIX] [DEST_DIR]
```
- `PREFIX` — LXC prefix (default: `ovpn-test-`)  
- `DEST_DIR` — local directory to store fetched logs (default: `../logs`)  

---

### 5. Destroy LXCs
```bash
./destroy-lxcs.sh [PREFIX]
```
- Deletes all LXCs with the given prefix (default: `ovpn-test-`)  

---

## How it works

1. **Template setup**: `launch-lxcs.sh` ensures a reusable LXC template (`ovpn-template`) exists with necessary packages.  
2. **LXC creation**: Clones the template for each test container.  
3. **File distribution**: `.ovpn` files from `ovpn-files/` are assigned to LXCs in round-robin fashion.  
4. **Test execution**: `test.sh` runs inside each LXC, attempting VPN connections and logging results.  
5. **Log aggregation**: `fetch-logs.sh` collects and merges `results.log` and `master_log.txt` into `logs/`.  
6. **Cleanup**: LXCs can be destroyed to free resources after testing.  

---

## Notes

- Round-robin distribution ensures `.ovpn` files are evenly tested across LXCs.  
- Each LXC runs tests **in parallel**.  
- Logs are saved per-LXC and merged into `logs/master_log_merged.txt` and `logs/results_merged.log`.  
- If a VPN connects but no internet is available, it is marked in logs.  
- Safe handling of Ctrl+C is implemented to clean up partially running VPN processes.  

---

## Example Workflow

Run all in one command:

```bash
./run-all.sh 5
```

Or step-by-step:

```bash
./launch-lxcs.sh 5
./start-tests.sh
./fetch-logs.sh
./destroy-lxcs.sh
```

---

## Contributing

- Add new scripts inside `scripts/` if needed.  
- Keep `.ovpn` files in `ovpn-files/`.