#!/bin/bash
# ============================================================
# WRT 抓包工具 - SSH 管道直传 Mac 本地
# 用法: ./wrt-capture.sh
# ============================================================
# ---- 配置 ----
WRT_HOST="root@[路由器IP]"
OUTPUT_DIR="$HOME/Desktop/wrt-captures/$(date +%Y-%m-%d)"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="wrt-capture_${TIMESTAMP}.pcap"
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"
WIRESHARK="/Applications/Wireshark.app/Contents/MacOS/Wireshark"

# ---- 颜色 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---- 退出处理 ----
show_summary() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
        if command -v capinfos &>/dev/null; then
            PKTS=$(capinfos -c "$OUTPUT_FILE" 2>/dev/null | grep "Number of packets" | awk '{print $4}')
            PKTS="${PKTS:-0}"
        else
            PKTS=$(wc -l < <(tcpdump -r "$OUTPUT_FILE" 2>/dev/null) | tr -d ' ')
        fi
        echo -e "  ${GREEN}✅ 抓包完成${NC}"
        echo -e "  文件: ${BOLD}${OUTPUT_FILE}${NC}"
        echo -e "  大小: ${SIZE}  |  包数: ${PKTS}"
        echo ""
        echo -e "  ${CYAN}用 Wireshark 分析:${NC}"
        echo "    open \"${OUTPUT_FILE}\""
        echo ""
        echo -e "  ${CYAN}丢给 AI 分析:${NC}"
        echo "    文件路径: ${OUTPUT_FILE}"
    else
        echo -e "  ${YELLOW}⚠ 未捕获到数据包${NC}"
        if [ -s "${OUTPUT_FILE}.log" ]; then
            echo -e "  排查日志: ${OUTPUT_FILE}.log"
        fi
    fi
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
}
trap 'echo ""; show_summary' INT

# ---- 依赖检查 ----
MISSING_DEPS=()
command -v ssh &>/dev/null || MISSING_DEPS+=("ssh")
command -v tcpdump &>/dev/null || MISSING_DEPS+=("tcpdump (本地)")
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}缺少依赖: ${MISSING_DEPS[*]}${NC}"
    exit 1
fi

# ---- 打印标题 ----
clear
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║       WRT 远程抓包工具 v1.0          ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# ---- 1. 选择接口 ----
echo -e "${BOLD}📡 选择抓包接口:${NC}"
echo ""

INTERFACES=(
    "any (所有网卡 - 推荐)"
    "br-lan (局域网桥接)"
    "wan (外网接口)"
    "ra0 (WiFi 2.4G)"
    "rax0 (WiFi 5G)"
    "eth0 (物理网口)"
)
IFACE_VALUES=("any" "br-lan" "wan" "ra0" "rax0" "eth0")

select choice in "${INTERFACES[@]}"; do
    if [ -n "$choice" ]; then
        INTERFACE="${IFACE_VALUES[$((REPLY-1))]}"
        break
    fi
    echo -e "${RED}无效选项，请重新选择${NC}"
done
echo ""

# ---- 2. 输入过滤 IP ----
echo -e "${BOLD}🎯 设备过滤（可选）:${NC}"
read -p "输入设备 IP 地址（留空抓全部设备）: " TARGET_IP
echo ""

# ---- 3. 是否排除 DNS ----
echo -e "${BOLD}🔒 排除 DNS 流量？${NC}"
echo "  排除 DNS 可减少噪音，但排查网络问题时 DNS 往往很关键"
read -p "  排除 DNS？[Y/n]: " EXCLUDE_DNS
echo ""

# ---- 4. 构造过滤规则 ----
FILTER="not port 22"
if [[ ! "$EXCLUDE_DNS" =~ ^[Nn] ]]; then
    FILTER="${FILTER} and not port 53"
    DNS_STATUS="排除"
else
    DNS_STATUS="保留"
fi
if [ -n "$TARGET_IP" ]; then
    FILTER="host ${TARGET_IP} and ${FILTER}"
    echo -e "${CYAN}接口:${NC} ${INTERFACE}   ${CYAN}过滤:${NC} ${TARGET_IP}   ${CYAN}排除:${NC} SSH(22)  DNS:${DNS_STATUS}"
else
    echo -e "${CYAN}接口:${NC} ${INTERFACE}   ${CYAN}过滤:${NC} 全部设备   ${CYAN}排除:${NC} SSH(22)  DNS:${DNS_STATUS}"
fi

# ---- 5. 连接检查 ----
WRT_IP="${WRT_HOST#*@}"
echo "🔗 检查连接 (${WRT_IP}) ..."
echo ""

# 先 ping 检查网络可达性
echo -n "  网络可达 (ping) ... "
if ! ping -c 2 -W 2 "${WRT_IP}" >/dev/null 2>&1; then
    echo -e "${RED}不可达${NC}"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ⚠ 无法连接到 WRT (${WRT_IP})${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "请检查:"
    echo "  1. WRT 是否已开机"
    echo "  2. Mac 和 WRT 是否在同一个局域网"
    echo "  3. WRT IP 是否正确 (当前: ${WRT_IP})"
    echo "  4. 手动 ping ${WRT_IP}"
    exit 1
fi
echo -e "${GREEN}可达${NC}"

# 再检查 SSH 免密登录
echo -n "  SSH 连接 (免密) ... "
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${WRT_HOST}" "echo ok" >/dev/null 2>&1; then
    echo -e "${RED}失败${NC}"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ⚠ SSH 免密登录未配置${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "请检查:"
    echo "  1. SSH 密钥是否配置: ssh-copy-id ${WRT_HOST}"
    echo "  2. 手动测试: ssh ${WRT_HOST}"
    exit 1
fi
echo -e "${GREEN}已连接${NC}"

# 检查 WRT 端 tcpdump 是否可用
echo -n "  tcpdump (WRT端) ... "
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${WRT_HOST}" "which tcpdump" >/dev/null 2>&1; then
    echo -e "${RED}未安装${NC}"
    echo ""
    echo -e "${RED}错误: WRT 上未找到 tcpdump${NC}"
    echo "  请在 WRT 上安装: opkg update && opkg install tcpdump"
    exit 1
fi
echo -e "${GREEN}已就绪${NC}"

# ---- 5. 开始抓包 ----
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🔴 正在抓包... 按 Ctrl+C 停止并保存${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ssh "${WRT_HOST}" "tcpdump -i ${INTERFACE} -s 0 -U -w - ${FILTER}" > "${OUTPUT_FILE}" 2>"${OUTPUT_FILE}.log" || true

# 正常退出也显示摘要
show_summary
