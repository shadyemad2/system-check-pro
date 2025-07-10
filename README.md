# Script: System Check Pro 🖥️🔐

**Author:** Shady Emad  
**Compatible with:** Most major Linux distributions (RHEL, CentOS, Ubuntu, Debian, etc.)

---

## 🚀 Overview

**System Check Pro** is a comprehensive Bash script that performs a full system audit for Linux machines. It checks:

- 🖥️ System Info  
- ⏱️ Date & Time  
- 📊 Resource Usage (RAM, CPU, Disk, Swap)  
- 🔥 Top Memory-Consuming Processes  
- 📁 Large Files (>100MB)  
- 🌐 Network Info (IP, DNS, Routes, Ping, MAC)  
- 🔐 Security Checks (failed logins, passwordless users, sudo users, firewall, SELinux)  
- 📡 Listening Ports  
- 🔒 Sensitive File Permissions  
- 🛠️ DevOps Tools Availability (`docker`, `kubectl`, `ansible`, etc.)

A clean and timestamped report is saved to the `output/` folder for further analysis.

---

## 📦 Output Example

After running the script, a report like this is saved:

```
output/system_report_2025-07-10_13-33-45.txt
```

You’ll see sections like:

```
=== System Information 🖥️ ===
Linux vm1.localdomain 5.14.0-427.el9.x86_64 ...

=== Users Without passwords: 🔐 ===
toto has no password!
ayman has no password!

=== DevOps Tools Availability 📦 ===
docker    : Available
kubectl   : Not Found
...
```

---

## 🛠️ How to Use

### Option 1: Clone and Run Locally

```bash
git clone https://github.com/shadyemad2/system-check-pro.git
cd system-check-pro
chmod +x script.sh
sudo ./script.sh
```

### Option 2: Run Directly via `curl` (one-liner)

> ⚠️ Requires root privileges

```bash
curl -sL https://raw.githubusercontent.com/shadyemad2/system-check-pro/main/script.sh | sudo bash
```

---

## 📁 Directory Structure

```
system-check-pro/
├── system_check.sh         # Main script
├── output/                 # Folder for saved reports
└── README.md               # Documentation
```

---

## ✅ Requirements

- Bash shell
- Root privileges
- Common system utilities like: `lscpu`, `df`, `ss` or `netstat`, `grep`, `awk`, etc.

---

## 🙌 Author

**Shady Emad**  
Linux & DevOps Enthusiast  

---

## 🧠 Future Ideas

- Export report as JSON / HTML  
- Email report to sysadmin  
- Add `--quick` or `--full` mode  
- GUI using Zenity or Whiptail

