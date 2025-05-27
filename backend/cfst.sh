# bash encrypt_pt_sites.sh encrypt
#!/bin/bash

# Cloudflare IP 优选管理脚本 (无标记版)
# 更新：支持批量添加/删除域名（空格/逗号分隔）
# 使用方法：保持与之前一致，参数可传入多个域名

# 配置参数
CF_DIR="/opt/CloudflareST"
CF_BIN="${CF_DIR}/CloudflareST"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PT_SITES_FILE="${SCRIPT_DIR}/pt_sites.json"
PT_SITES_ENC="${SCRIPT_DIR}/pt_sites.enc"
ENCRYPTION_KEY="dqwoidjdaksnkjrn@938475"

# 下载配置文件
download_config() {
    local config_url="https://raw.githubusercontent.com/vanchKong/cloudflare/refs/heads/main/pt_sites.enc"
    local mirrors=(
        "$config_url"
        "https://ghproxy.com/$config_url"
        "https://ghfast.top/$config_url"
        "https://ghproxy.net/$config_url"
        "https://gh-proxy.com/$config_url"
    )
    
    echo "📥 正在下载配置文件..." >&2
    for url in "${mirrors[@]}"; do
        if wget --tries=2 --waitretry=1 --show-progress --timeout=20 -O "${PT_SITES_ENC}.tmp" "$url"; then
            # 验证下载的文件是否可解密
            if openssl enc -aes-256-cbc -pbkdf2 -d -salt -in "${PT_SITES_ENC}.tmp" -out "$PT_SITES_FILE" -pass pass:"$ENCRYPTION_KEY" 2>/dev/null; then
                mv "${PT_SITES_ENC}.tmp" "$PT_SITES_ENC"
                rm -f "$PT_SITES_FILE"
                echo "✅ 配置文件更新成功" >&2
                return 0
            fi
        fi
    done
    
    rm -f "${PT_SITES_ENC}.tmp"
    echo "⚠️ 配置文件下载失败，将使用本地文件" >&2
    return 1
}

# 检查配置文件
check_config() {
    if [ ! -f "$PT_SITES_ENC" ]; then
        echo "❌ 未找到配置文件，请确保 pt_sites.enc 文件存在" >&2
        exit 1
    fi
}

# 域名隐私处理
mask_domain() {
    local domain=$1
    local tld=$(echo "$domain" | grep -o '[^.]*$')
    local masked_tld=$(printf '%*s' ${#tld} '' | tr ' ' 'x')
    echo "${domain%.*}.$masked_tld"
}

# 检查并安装依赖
check_dependencies() {
    # 检查 jq
    if ! command -v jq &> /dev/null; then
        echo "正在安装 jq..."
        if command -v apt-get &> /dev/null; then
            apt-get update -o Acquire::AllowInsecureRepositories=true -o Acquire::AllowDowngradeToInsecureRepositories=true 2>/dev/null
            apt-get install -y jq 2>/dev/null
        elif command -v yum &> /dev/null; then
            yum install -y jq 2>/dev/null
        elif command -v dnf &> /dev/null; then
            dnf install -y jq 2>/dev/null
        elif command -v pacman &> /dev/null; then
            pacman -Sy --noconfirm jq 2>/dev/null
        elif command -v brew &> /dev/null; then
            brew install jq 2>/dev/null
        else
            echo "❌ 无法安装 jq，请手动安装后重试"
            exit 1
        fi
        
        # 验证安装是否成功
        if ! command -v jq &> /dev/null; then
            echo "❌ jq 安装失败，请手动安装后重试"
            exit 1
        fi
    fi
}

# 架构检测
setup_arch() {
    case $(uname -m) in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        *)       echo "unsupported" ;;
    esac
}

# 检查域名响应头
check_domain_headers() {
    local domain=$1
    local expected_cf=$2
    local max_retries=3
    local retry_count=0
    local headers=""
    local masked_domain=$(mask_domain "$domain")
    
    echo "🔍 检查域名: $masked_domain" >&2
    while [ $retry_count -lt $max_retries ]; do
        echo -n "." >&2
        headers=$(curl -sI "https://$domain" --connect-timeout 10 | grep -i 'server:')
        if [ ! -z "$headers" ]; then
            echo >&2  # 换行
            if [[ "$headers" =~ [Cc]loudflare ]]; then
                if [ "$expected_cf" = "false" ]; then
                    echo "⚠️ $masked_domain: 实际为 Cloudflare 托管，但配置文件中设置为非托管" >&2
                fi
                echo "✅ $masked_domain: Cloudflare 托管" >&2
                echo "cf"
            else
                if [ "$expected_cf" = "true" ]; then
                    echo "⚠️ $masked_domain: 实际非 Cloudflare 托管，但配置文件中设置为托管" >&2
                fi
                echo "ℹ️ $masked_domain: 非 Cloudflare 托管" >&2
                echo "non-cf"
            fi
            return 0
        fi
        retry_count=$((retry_count + 1))
        [ $retry_count -lt $max_retries ] && echo "⚠️ $masked_domain: 第 $retry_count 次重试..." >&2 && sleep 2
    done
    
    echo >&2  # 换行
    echo "❌ $masked_domain: 无法获取响应头，根据预设配置决定是否强制添加优选，不保证绝对正确！可主动确认该域名是否托管于 Cloudflare，手动修改 /etc/hosts 文件" >&2
    echo "unknown"
    return 1
}

# 获取当前优选IP
get_current_ip() {
    if [ -f "${CF_DIR}/result.csv" ]; then
        awk -F ',' 'NR==2 {print $1}' "${CF_DIR}/result.csv"
    else
        # 如果没有优选结果，返回默认IP
        echo "1.1.1.1"
    fi
}

# 从加密文件加载 PT 站点域名
load_pt_domains() {
    if [ -f "$PT_SITES_ENC" ]; then
        echo "📦 正在解密配置文件..." >&2
        # 解密文件
        if ! openssl enc -aes-256-cbc -pbkdf2 -d -salt -in "$PT_SITES_ENC" -out "$PT_SITES_FILE" -pass pass:"$ENCRYPTION_KEY"; then
            echo "❌ 解密文件失败" >&2
            exit 1
        fi

        echo "🔍 验证 JSON 格式..." >&2
        # 验证 JSON 文件格式
        if ! jq empty "$PT_SITES_FILE" 2>/dev/null; then
            echo "❌ JSON 文件格式错误" >&2
            exit 1
        fi
        
        # 读取所有域名并检查状态
        local domains=()
        local site_count=$(jq '.sites | length' "$PT_SITES_FILE")
        echo "📊 发现 $site_count 个站点" >&2
        
        # 计算总域名数
        local total_domains=$(jq '[.sites[].domains[], .sites[].trackers[]] | length' "$PT_SITES_FILE")
        local current_domain=0
        
        for ((i=0; i<$site_count; i++)); do
            local site_name=$(jq -r ".sites[$i].name" "$PT_SITES_FILE")
            echo "🌐 处理站点: $site_name" >&2
            # 获取当前站点的所有域名
            local site_domains=()
            
            # 处理主域名
            while IFS= read -r line; do
                if [ -z "$line" ]; then
                    continue
                fi
                domain=$(echo "$line" | jq -r '.domain // empty')
                if [ -z "$domain" ]; then
                    continue
                fi
                is_cf=$(echo "$line" | jq -r '.is_cf // false')
                current_domain=$((current_domain + 1))
                echo -n "[$current_domain/$total_domains] " >&2
                
                # 检查域名状态
                actual_status=$(check_domain_headers "$domain" "$is_cf")
                
                # 根据检查结果决定是否添加
                if [ "$actual_status" = "unknown" ]; then
                    # 如果无法获取响应头，使用预设值
                    if [ "$is_cf" = "true" ]; then
                        echo "➕ 添加域名(预设): $(mask_domain "$domain")" >&2
                        site_domains+=("$domain")
                    fi
                elif [ "$actual_status" = "cf" ]; then
                    # 如果确认是 CF 托管，添加域名
                    echo "➕ 添加域名(CF): $(mask_domain "$domain")" >&2
                    site_domains+=("$domain")
                fi
            done < <(jq -c ".sites[$i].domains[]" "$PT_SITES_FILE")
            
            # 处理 tracker 域名
            while IFS= read -r line; do
                if [ -z "$line" ]; then
                    continue
                fi
                domain=$(echo "$line" | jq -r '.domain // empty')
                if [ -z "$domain" ]; then
                    continue
                fi
                is_cf=$(echo "$line" | jq -r '.is_cf // false')
                current_domain=$((current_domain + 1))
                echo -n "[$current_domain/$total_domains] " >&2
                
                # 检查域名状态
                actual_status=$(check_domain_headers "$domain" "$is_cf")
                
                # 根据检查结果决定是否添加
                if [ "$actual_status" = "unknown" ]; then
                    # 如果无法获取响应头，使用预设值
                    if [ "$is_cf" = "true" ]; then
                        echo "➕ 添加 tracker(预设): $(mask_domain "$domain")" >&2
                        site_domains+=("$domain")
                    fi
                elif [ "$actual_status" = "cf" ]; then
                    # 如果确认是 CF 托管，添加域名
                    echo "➕ 添加 tracker(CF): $(mask_domain "$domain")" >&2
                    site_domains+=("$domain")
                fi
            done < <(jq -c ".sites[$i].trackers[]" "$PT_SITES_FILE")
            
            # 将当前站点的所有域名添加到总列表
            domains+=("${site_domains[@]}")
        done
        
        # 清理临时文件
        rm -f "$PT_SITES_FILE"
        
        if [ ${#domains[@]} -eq 0 ]; then
            echo "❌ 没有找到有效的域名" >&2
            exit 1
        fi
        
        echo "✅ 域名处理完成，共 ${#domains[@]} 个域名" >&2
        printf "%s\n" "${domains[@]}"
    else
        echo "❌ 未找到加密的站点配置文件" >&2
        exit 1
    fi
}

# 初始化环境
init_setup() {
    echo "作者：端端🐱/Gotchaaa，玩得开心～"
    echo "感谢 windfree、tianting 帮助完善站点数据"
    echo "使用姿势请查阅：https://github.com/vanchKong/cloudflare"
    
    # 检查并安装依赖
    check_dependencies
    
    [ ! -d "$CF_DIR" ] && mkdir -p "$CF_DIR"
    
    # 获取当前优选 IP
    current_ip=$(get_current_ip)
    
    # 加载并获取有效的域名列表
    domains=($(load_pt_domains))
    
    # 删除加密文件中存在的域名的所有记录
    cat /etc/hosts > /etc/hosts.tmp
    for domain in "${domains[@]}"; do
        grep -v " ${domain}$" /etc/hosts.tmp > /etc/hosts.tmp2
        mv /etc/hosts.tmp2 /etc/hosts.tmp
    done
    cat /etc/hosts.tmp > /etc/hosts
    rm -f /etc/hosts.tmp
    
    # 重新添加加密文件中的域名记录
    for domain in "${domains[@]}"; do
        echo "${current_ip} ${domain}" >> /etc/hosts
    done
    
    echo "✅ 已初始化 hosts 文件"
    
    # 下载 CloudflareST
    if [ ! -f "$CF_BIN" ]; then
        arch=$(setup_arch)
        [ "$arch" = "unsupported" ] && echo "不支持的架构" && exit 1
        
        filename="CloudflareST_linux_${arch}.tar.gz"
        mirrors=(
            "https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/$filename"
            "https://ghproxy.com/https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/$filename"
            "https://ghfast.top/https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/$filename"
            "https://ghproxy.net/https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/$filename"
            "https://gh-proxy.com/https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.2.5/$filename"
        )

        for url in "${mirrors[@]}"; do
            if wget --tries=2 --waitretry=1 --show-progress --timeout=20 -O "${CF_DIR}/$filename" "$url"; then
                tar -zxf "${CF_DIR}/$filename" -C "$CF_DIR" && chmod +x "$CF_BIN"
                rm "${CF_DIR}/$filename"
                return 0
            fi
        done
        echo "下载失败" && exit 1
    fi
}

# 添加单个域名
add_single_domain() {
    local domain=$1
    local result=""
    local current_ip=$(get_current_ip)

    # 检测格式并检查是否存在
    if grep -q " ${domain}$" /etc/hosts; then
        # 获取当前域名使用的 IP
        local existing_ip=$(grep " ${domain}$" /etc/hosts | awk '{print $1}')
        
        # 检查域名状态
        actual_status=$(check_domain_headers "$domain" "unknown")
        if [ "$actual_status" = "cf" ]; then
            if [ "$existing_ip" = "$current_ip" ]; then
                echo "域名已存在且使用当前优选IP: $domain" >&2
                result="{\"domain\":\"$domain\",\"status\":\"已存在\",\"ip\":\"$current_ip\"}"
            else
                # 更新为当前优选 IP
                cat /etc/hosts | grep -v " ${domain}$" > /etc/hosts.tmp
                echo "${current_ip} ${domain}" >> /etc/hosts.tmp
                cat /etc/hosts.tmp > /etc/hosts
                rm -f /etc/hosts.tmp
                echo "域名已存在，已更新为当前优选IP: $domain" >&2
                result="{\"domain\":\"$domain\",\"status\":\"已更新\",\"ip\":\"$current_ip\"}"
            fi
        else
            echo "域名已存在但非CF托管: $domain" >&2
            result="{\"domain\":\"$domain\",\"status\":\"非CF托管\",\"ip\":\"$existing_ip\"}"
        fi
    else
        # 检查域名状态
        actual_status=$(check_domain_headers "$domain" "unknown")
        if [ "$actual_status" = "cf" ]; then
            echo "${current_ip} ${domain}" >> /etc/hosts
            echo "添加域名成功: $domain" >&2
            result="{\"domain\":\"$domain\",\"status\":\"添加成功\",\"ip\":\"$current_ip\"}"
        else
            echo "跳过非CF域名: $domain" >&2
            result="{\"domain\":\"$domain\",\"status\":\"未添加\",\"ip\":\"\"}"
        fi
    fi
    # 只输出 JSON 结果，不输出其他内容
    printf "%s" "$result"
}

# 删除单个域名
del_single_domain() {
    local domain=$1
    local result=""
    
    # 从hosts中删除
    if grep -q " ${domain}$" /etc/hosts; then
        # 使用 cat 和重定向方式修改
        cat /etc/hosts | grep -v " ${domain}$" > /etc/hosts.new && cat /etc/hosts.new > /etc/hosts && rm -f /etc/hosts.new
        echo "已移除域名: $domain" >&2
        result="{\"domain\":\"$domain\",\"status\":\"删除成功\",\"ip\":\"\"}"
    else
        echo "域名不存在: $domain" >&2
        result="{\"domain\":\"$domain\",\"status\":\"不存在\",\"ip\":\"\"}"
    fi
    # 只输出 JSON 结果，不输出其他内容
    printf "%s" "$result"
}

# 查看托管列表
list_domains() {
    # echo "当前优选的域名列表："
    current_ip=$(get_current_ip)
    
    if [ -z "$current_ip" ]; then
        echo "❌ 未找到当前优选 IP" >&2
        echo -n "{\"code\":1,\"message\":\"未找到优选 IP\",\"data\":[]}"
        exit 1
    fi

    # 从 hosts 文件中获取当前优选 IP 对应的所有域名
    if [ -f "/etc/hosts" ]; then
        # 开始构建 JSON 对象
        echo -n "{\"code\":0,\"message\":\"success\",\"data\":["
        first=true
        
        # 读取并显示域名
        while IFS= read -r line; do
            # 跳过注释行和空行
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            
            # 提取 IP 和域名
            ip=$(echo "$line" | awk '{print $1}')
            domain=$(echo "$line" | awk '{print $2}')
            
            # 只处理当前优选 IP 的域名
            if [ "$ip" = "$current_ip" ]; then
                # 显示域名到控制台
                echo "$domain" >&2
                
                # 添加到 JSON 输出
                if [ "$first" = true ]; then
                    first=false
                else
                    echo -n ","
                fi
                echo -n "{\"ip\":\"$ip\",\"domain\":\"$domain\"}"
            fi
        done < /etc/hosts
        
        # 结束 JSON 对象
        echo -n "]}"
    else
        echo "❌ 未找到 hosts 文件" >&2
        echo -n "{\"code\":1,\"message\":\"未找到 hosts 文件\",\"data\":[]}"
        exit 1
    fi
}

# 执行优选并更新所有域名
run_update() {
    # 获取当前优选 IP
    local current_ip=$(get_current_ip)
    [ -z "$current_ip" ] && echo "❌ 未找到当前优选 IP" && exit 1
    
    echo "⏳ 开始优选测试..."
    cd "$CF_DIR" && ./CloudflareST -dn 8 -tl 400 -sl 1
    
    # 获取新的优选 IP
    local best_ip=$(get_current_ip)
    [ -z "$best_ip" ] && echo "❌ 优选失败" && exit 1
    
    echo "🔄 正在更新 hosts 文件..."
    
    # 使用 grep 和重定向方式更新 hosts 文件
    cat /etc/hosts > /etc/hosts.tmp
    while IFS= read -r line; do
        if [[ "$line" =~ ^${current_ip}[[:space:]] ]]; then
            echo "$line" | sed "s/^${current_ip} /${best_ip} /" >> /etc/hosts.tmp2
        else
            echo "$line" >> /etc/hosts.tmp2
        fi
    done < /etc/hosts.tmp
    cat /etc/hosts.tmp2 > /etc/hosts
    rm -f /etc/hosts.tmp /etc/hosts.tmp2
    
    echo "✅ 所有域名已更新到最新IP: $best_ip"
}

# 主流程
main() {
    [ "$(id -u)" -ne 0 ] && echo "需要root权限" >&2 && exit 1
    
    case "$1" in
        "-add")
            shift
            download_config
            [ $# -eq 0 ] && echo "需要域名参数" >&2 && exit 1
            # 将输入字符串分割成数组
            domains=($(echo "$@" | tr ' ' '\n' | tr ',' '\n' | grep -v '^$'))
            if [ ${#domains[@]} -eq 0 ]; then
                printf "{\"code\":1,\"message\":\"没有有效的域名\",\"data\":[]}"
                exit 1
            fi
            
            # 开始构建 JSON 数组
            printf "{\"code\":0,\"message\":\"success\",\"data\":["
            first=true
            for domain in "${domains[@]}"; do
                if [ "$first" = true ]; then
                    first=false
                else
                    printf ","
                fi
                add_single_domain "$domain"
            done
            printf "]}"
            ;;
        "-del")
            shift
            [ $# -eq 0 ] && echo "需要域名参数" >&2 && exit 1
            # 将输入字符串分割成数组
            domains=($(echo "$@" | tr ' ' '\n' | tr ',' '\n' | grep -v '^$'))
            if [ ${#domains[@]} -eq 0 ]; then
                printf "{\"code\":1,\"message\":\"没有有效的域名\",\"data\":[]}"
                exit 1
            fi
            
            # 开始构建 JSON 数组
            printf "{\"code\":0,\"message\":\"success\",\"data\":["
            first=true
            for domain in "${domains[@]}"; do
                if [ "$first" = true ]; then
                    first=false
                else
                    printf ","
                fi
                del_single_domain "$domain"
            done
            printf "]}"
            ;;
        "-list")
            list_domains
            ;;
        *)
    # 尝试下载并更新配置文件
    download_config
    
    # 检查配置文件是否存在
    check_config
    init_setup
    run_update
    ;;
    esac
}

main "$@"
