#!/bin/bash

# 加密密钥（建议使用随机生成的密钥）
ENCRYPTION_KEY="dqwoidjdaksnkjrn@938475"

# 加密函数
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    
    # 使用 openssl 进行加密
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$input_file" -out "$output_file" -pass pass:"$ENCRYPTION_KEY"
    echo "✅ 文件已加密: $output_file"
}

# 解密函数
decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    
    # 使用 openssl 进行解密
    openssl enc -aes-256-cbc -pbkdf2 -d -salt -in "$input_file" -out "$output_file" -pass pass:"$ENCRYPTION_KEY"
    echo "✅ 文件已解密: $output_file"
}

# 主函数
main() {
    case "$1" in
        "encrypt")
            encrypt_file "pt_sites.json" "pt_sites.enc"
            ;;
        "decrypt")
            decrypt_file "pt_sites.enc" "pt_sites.json"
            ;;
        *)
            echo "用法: $0 [encrypt|decrypt]"
            exit 1
            ;;
    esac
}

main "$@" 