from flask import Flask, request, jsonify, send_from_directory
import subprocess
import os
import json

app = Flask(__name__, static_folder='static', static_url_path='/')

def run_command(command, capture_output=False):
    """运行命令并处理输出
    
    Args:
        command: 要运行的命令列表
        capture_output: 是否捕获输出作为返回值
    
    Returns:
        如果 capture_output 为 True，返回 (stdout, stderr)
        否则返回 None，输出直接显示在控制台
    """
    if capture_output:
        process = subprocess.Popen(command,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE,
                                 universal_newlines=True)
        return process.communicate()
    else:
        process = subprocess.Popen(command,
                                 stdout=None,
                                 stderr=None,
                                 universal_newlines=True)
        process.wait()
        return None

@app.route('/api/add', methods=['POST'])
def add_domain():
    domains = request.json.get('domain', '').split()
    if not domains:
        return jsonify({'code': 1, 'message': '域名不能为空', 'data': None})
    
    # 直接传递所有域名给脚本处理
    stdout, stderr = run_command(['bash', 'cfst.sh', '-add'] + domains, capture_output=True)
    print(stdout)
    
    try:
        return jsonify(json.loads(stdout))
    except json.JSONDecodeError:
        return jsonify({'code': 1, 'message': '解析返回数据失败', 'data': None})

@app.route('/api/del', methods=['POST'])
def del_domain():
    domains = request.json.get('domain', '').split()
    if not domains:
        return jsonify({'code': 1, 'message': '域名不能为空', 'data': None})
    
    # 直接传递所有域名给脚本处理
    stdout, stderr = run_command(['bash', 'cfst.sh', '-del'] + domains, capture_output=True)
    print(stdout)
    
    try:
        return jsonify(json.loads(stdout))
    except json.JSONDecodeError:
        return jsonify({'code': 1, 'message': '解析返回数据失败', 'data': None})

@app.route('/api/list')
def list_domains():
    stdout, stderr = run_command(['bash', 'cfst.sh', '-list'], capture_output=True)
    try:
        print(stdout)
        return jsonify(json.loads(stdout))
    except json.JSONDecodeError:
        return jsonify({'code': 1, 'message': '解析返回数据失败', 'data': []})

@app.route('/api/update')
def update_domains():
    # 直接运行命令，输出显示在控制台
    run_command(['bash', 'cfst.sh'])
    return jsonify({'code': 0, 'message': '优选完成', 'data': None})

@app.route('/api/update/<domain>')
def update_single_domain(domain):
    # 直接运行命令，输出显示在控制台
    run_command(['bash', 'cfst.sh', '-add', domain])
    return jsonify({'code': 0, 'message': f'域名 {domain} 优选完成', 'data': None})

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_vue(path):
    # 如果请求的是静态文件，直接返回
    file_path = os.path.join(app.static_folder, path)
    if path != "" and os.path.exists(file_path):
        return send_from_directory(app.static_folder, path)
    # 其他情况一律返回 index.html
    return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9731)