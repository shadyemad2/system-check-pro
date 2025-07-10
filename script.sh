#!/bin/bash

# ========================================
# System Check Pro - Shady Emad 
# ========================================
# Comprehensive Linux Health, Security & Performance Audit
# Works across most major Linux distributions
# ========================================



# ----------[ Config ]----------

OUTPUT_DIR="./output"
mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/system_report_$(date +%Y-%m-%d_%H-%M-%S).txt"

# ----------[ Colors ]----------
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ----------[ Root Check ]----------
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}This script must be run as root. Try: sudo $0${NC}"
  exit 1
fi

# ----------[ Helpers ]----------
print_header() {
  echo -e "\n${CYAN}======= $1 =======${NC}"
  echo -e "\n======= $1 =======" >> "$REPORT_FILE"
}

# ----------[ System Info ]----------
system_info(){
  print_header "System Information"
  uname -a | tee -a "$REPORT_FILE"
  [[ -f /etc/os-release ]] && cat /etc/os-release | tee -a "$REPORT_FILE" || echo "/etc/os-release not found, skipping.." | tee -a "$REPORT_FILE"
  hostnamectl 2>/dev/null | tee -a "$REPORT_FILE" || echo "Hostname: $(hostname)" | tee -a "$REPORT_FILE"
  echo "CPU Cores: $(nproc)" | tee -a "$REPORT_FILE"
  lscpu 2>/dev/null | grep "Model name" | tee -a "$REPORT_FILE"
}

# ----------[ Date & Time Info ]----------
time_info(){
  print_header "Date & Time"
  date | tee -a "$REPORT_FILE"
  if command -v timedatectl &>/dev/null; then
    timedatectl | grep -E 'Time zone|NTP|System clock' | tee -a "$REPORT_FILE"
  else
    echo "timedatectl not found" | tee -a "$REPORT_FILE"
  fi
}

# ----------[ Resource Usage ]----------
resource_usage(){
  print_header "Resource Usage"
  uptime -p | tee -a "$REPORT_FILE"

  echo -e "\n${YELLOW}Memory Usage:${NC}"
  echo -e "\nMemory Usage:" >> "$REPORT_FILE"
  (free -h 2>/dev/null || head -n 3 /proc/meminfo) | tee -a "$REPORT_FILE"

  echo -e "\n${YELLOW}Disk Usage:${NC}"
  echo -e "\nDisk Usage:" >> "$REPORT_FILE"
  df -h | tee -a "$REPORT_FILE"

  echo -e "\n${YELLOW}Inode Usage:${NC}"
  echo -e "\nInode Usage:" >> "$REPORT_FILE"
  df -i | tee -a "$REPORT_FILE"

  echo -e "\n${YELLOW}Swap Status:${NC}"
  echo -e "\nSwap Status:" >> "$REPORT_FILE"
  (swapon --show 2>/dev/null || echo "No Swap enabled") | tee -a "$REPORT_FILE"
}

# ----------[ Top Processes ]----------
top_processes(){
  print_header "Top Memory-Consuming Processes"
  ps aux --sort=-%mem | head -n 6 | tee -a "$REPORT_FILE"
}

# ----------[ Large Files ]----------
large_files(){
  print_header "Large Files (>100MB)"
  results=$(find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k 5 -hr | head -n 5)
  [[ -z "$results" ]] && echo "No large files found (over 100MB)" | tee -a "$REPORT_FILE" || echo "$results" | tee -a "$REPORT_FILE"
}

# ----------[ Network Info ]----------
network_info(){
  print_header "Network Information"
  (ip address 2>/dev/null || ifconfig 2>/dev/null) | tee -a "$REPORT_FILE"

  echo -e "\nRouting Table:" 
  echo -e "\nRouting Table:" >> "$REPORT_FILE"
  (route -n 2>/dev/null || ip route 2>/dev/null) | tee -a "$REPORT_FILE"

  echo -e "\nDNS Servers:"
  echo -e "\nDNS Servers:" >> "$REPORT_FILE"
  grep nameserver /etc/resolv.conf | tee -a "$REPORT_FILE"

  echo -e "\nPing Test (8.8.8.8):"
  echo -e "\nPing Test (8.8.8.8):" >> "$REPORT_FILE"
  ping -c 3 8.8.8.8 | tee -a "$REPORT_FILE"

  echo -e "\nMAC Address:"
  echo -e "\nMAC Address:" >> "$REPORT_FILE"
  (ip link | grep ether || ifconfig | grep ether) | tee -a "$REPORT_FILE"
}

# ----------[ Security Check ]----------
security_check() {
  print_header "Security Check"

  echo -e "\n${YELLOW}Last Failed Login Attempts:${NC}"
  echo -e "\nLast Failed Login Attempts:" >> "$REPORT_FILE"
  if [[ -f /var/log/auth.log ]]; then
    grep "Failed password" /var/log/auth.log | tail -n 10 | tee -a "$REPORT_FILE"
  elif [[ -f /var/log/secure ]]; then
    grep "Failed password" /var/log/secure | tail -n 10 | tee -a "$REPORT_FILE"
  else
    echo "No authentication log found" | tee -a "$REPORT_FILE"
  fi

  echo -e "\n${YELLOW}Users Without passwords:${NC}"
  echo -e "\nUsers Without passwords:" >> "$REPORT_FILE"
  results=$(
  awk -F: '($2 == "!!") {print $1}' /etc/shadow 2>/dev/null | while read user; do
    shell=$(getent passwd "$user" | cut -d: -f7)
    uid=$(getent passwd "$user" | cut -d: -f3)
    if [[ "$uid" -ge 1000 && "$shell" =~ /(bash|sh)$ ]]; then
      echo "$user has no password!"
    fi
  done
  )

  if [[ -z "$results" ]]; then
   echo " No real users without passwords found." | tee -a "$REPORT_FILE"
  else
   echo "$results" | tee -a "$REPORT_FILE"
  fi

  echo -e "\n${YELLOW}Effective sudo users:${NC}"
  echo -e "\nEffective sudo users:" >> "$REPORT_FILE"
  group_users=$(getent group wheel || getent group sudo | cut -d: -f4 | tr ',' '\n' | sort -u)
  file_users=$(grep -hE '^[a-zA-Z0-9._-]+\s+ALL' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | awk '{print $1}' | sort -u)
  all_sudo_users=$(echo -e "$group_users\n$file_users" | sort -u | sed '/^$/d')
  [[ -z "$all_sudo_users" ]] && echo "No sudo users found" | tee -a "$REPORT_FILE" || {
    echo "$all_sudo_users" | tee -a "$REPORT_FILE"
    echo "Total: $(echo "$all_sudo_users" | wc -l)" | tee -a "$REPORT_FILE"
  }

  echo -e "\n${YELLOW}Firewall Rules:${NC}"
  echo -e "\nFirewall Rules:" >> "$REPORT_FILE"
  if pidof firewalld &>/dev/null; then
    echo "firewalld is running" | tee -a "$REPORT_FILE"
    echo -e "\nOpen Ports:" >> "$REPORT_FILE"
    firewall-cmd --list-ports 2>/dev/null | tee -a "$REPORT_FILE"
    echo -e "\nAllowed Services:" >> "$REPORT_FILE"
    firewall-cmd --list-services 2>/dev/null | tee -a "$REPORT_FILE"
  elif command -v iptables &>/dev/null; then
    echo "firewalld not running. iptables rules:" | tee -a "$REPORT_FILE"
    iptables -L -n -v 2>/dev/null | grep -E 'ACCEPT|REJECT|DROP' | tee -a "$REPORT_FILE"
  else
    echo "No firewall tool (firewalld or iptables) found" | tee -a "$REPORT_FILE"
  fi

  echo -e "\n${YELLOW}SELinux Status:${NC}"
  echo -e "\nSELinux Status:" >> "$REPORT_FILE"
  if command -v getenforce &>/dev/null; then
    getenforce | tee -a "$REPORT_FILE"
  elif [[ -f /etc/selinux/config ]]; then
    grep -i '^SELINUX=' /etc/selinux/config | tee -a "$REPORT_FILE"
  else
    echo "SELinux tools not available" | tee -a "$REPORT_FILE"
  fi
}

# ----------[ Listening Ports ]----------
listening_ports() {
  print_header "Listening Ports"
  echo -e "${YELLOW}\nProto  Address:Port        State      PID/Program${NC}"
  echo -e "\nListening Ports:" >> "$REPORT_FILE"
  if command -v netstat &>/dev/null; then
    netstat -tulnp | awk 'NR>2 {print $1, $4, $6, $7}' | column -t | tee -a "$REPORT_FILE"
  elif command -v ss &>/dev/null; then
     ss -tulnp | awk 'NR>1 {print $1, $5, $6, $7}' | column -t | tee -a "$REPORT_FILE"
  else
    echo "Neither ss nor netstat found" | tee -a "$REPORT_FILE"
  fi
}

# ----------[ DevOps Tools Check ]----------
devops_tools() {
  print_header "DevOps Tools Availability"
  local tools=("docker" "kubectl" "mc" "helm" "ansible" "terraform" "git")
  for tool in "${tools[@]}"; do
    printf "%-10s: " "$tool"
    echo -n "$tool: " >> "$REPORT_FILE"
    if command -v "$tool" &>/dev/null; then
      echo -e "${GREEN}Available${NC}"
      echo "Available" >> "$REPORT_FILE"
    else
      echo -e "${RED}Not Found${NC}"
      echo "Not Found" >> "$REPORT_FILE"
    fi
  done
}

# ----------[ Critical Services Check ]--------

# ----------[ Critical Services Check ]----------

check_services() {
  print_header "Critical Services Status"

  local services=("sshd" "firewalld" "iptables" "docker" "nginx" "httpd" "mysql" "mariadb" "crond" "rsyslog" "kubelet")

  for service in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
      status=$(systemctl is-active "$service" 2>/dev/null)
      enabled_raw=$(systemctl is-enabled "$service" 2>/dev/null)

      [[ "$status" == "active" ]] && status_colored="${GREEN}Running${NC}" || status_colored="${RED}Not Running${NC}"
      [[ "$enabled_raw" == "enabled" ]] && enabled_colored="${GREEN}Enabled${NC}" || enabled_colored="${RED}Not Enabled${NC}"

      echo -e "$service: $status_colored, $enabled_colored"
      echo "$service: $status, Enabled: $enabled_raw" >> "$REPORT_FILE"
    else
      echo -e "$service: ${YELLOW}Not Installed${NC}"
      echo "$service: Not Installed" >> "$REPORT_FILE"
    fi
  done
}

    
# ----------[ Cleanup Old Reports ]----------
cleanup_old_reports() {
  cd "$OUTPUT_DIR" || return
  ls -t system_report_*.txt | tail -n +2 | xargs -r rm -f
}


# ----------[ Main ]----------
main() {
  echo -e "${CYAN}Generating System Report...${NC}"
  echo "Generating System Report..." >> "$REPORT_FILE"
  system_info
  time_info
  resource_usage
  top_processes
  large_files
  network_info
  security_check
  listening_ports
  check_services
  devops_tools
  echo -e "\n${GREEN}✅ Report saved to: $REPORT_FILE${NC}"
  echo -e "\n✅ Report saved to: $REPORT_FILE" >> "$REPORT_FILE"
}

main
cleanup_old_reports
