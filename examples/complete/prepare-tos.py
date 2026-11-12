#!/usr/bin/env python3
"""部署前检查 TOS RenameObject 并准备 Spark 事件日志目录。"""

import argparse
import datetime
import hashlib
import hmac
import json
import os
import re
import sys
import urllib.error
import urllib.request
from urllib.parse import quote


def request(method, bucket, region, key, access_key, secret_key,
            query="", payload=b"", read_json=False):
    host = f"{bucket}.tos-{region}.volces.com"
    path = "/" + quote(key, safe="/~")
    date = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    headers = {
        "host": host,
        "x-tos-date": date,
        "x-tos-content-sha256": hashlib.sha256(payload).hexdigest(),
    }
    if payload:
        headers["content-type"] = "application/json"
    token = os.environ.get("VOLCENGINE_SESSION_TOKEN")
    if token:
        headers["x-tos-security-token"] = token
    signed_headers = ";".join(sorted(headers))
    canonical = "\n".join([
        method, path, query,
        "".join(f"{name}:{headers[name]}\n" for name in sorted(headers)),
        signed_headers, headers["x-tos-content-sha256"],
    ])
    scope = f"{date[:8]}/{region}/tos/request"
    to_sign = "\n".join([
        "TOS4-HMAC-SHA256", date, scope,
        hashlib.sha256(canonical.encode()).hexdigest(),
    ])
    signing_key = secret_key.encode()
    for part in (date[:8], region, "tos", "request"):
        signing_key = hmac.new(signing_key, part.encode(), hashlib.sha256).digest()
    signature = hmac.new(signing_key, to_sign.encode(), hashlib.sha256).hexdigest()
    headers["Authorization"] = (
        f"TOS4-HMAC-SHA256 Credential={access_key}/{scope}, "
        f"SignedHeaders={signed_headers}, Signature={signature}"
    )
    req = urllib.request.Request(
        f"https://{host}{path}" + (f"?{query}" if query else ""),
        method=method, headers=headers,
        data=payload if method == "PUT" else None,
    )
    try:
        # 签名请求不跟随重定向，避免向其他地址发送认证头。
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                return None

        with urllib.request.build_opener(NoRedirect).open(req, timeout=20) as response:
            if read_json:
                return response.status, json.load(response)
            return response.status
    except urllib.error.HTTPError as error:
        if read_json:
            return error.code, {}
        return error.code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bucket", required=True, help="与 tos_bucket_name 一致的桶名称")
    parser.add_argument("--region", required=True, help="TOS Bucket 所在地域")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="只检查，不修改桶或目录")
    mode.add_argument("--enable-rename", action="store_true",
                      help="按需开启桶的 RenameObject；与版本控制互斥")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{1,61}[a-z0-9]", args.bucket):
        parser.error("Bucket 名称格式不正确")
    if not re.fullmatch(r"[a-z]{2}(?:-[a-z0-9]+)+", args.region):
        parser.error("地域格式不正确")
    access_key = os.environ.get("VOLCENGINE_ACCESS_KEY")
    secret_key = os.environ.get("VOLCENGINE_SECRET_KEY")
    if not access_key or not secret_key:
        parser.error("请设置 VOLCENGINE_ACCESS_KEY 和 VOLCENGINE_SECRET_KEY")

    def send(method, key, **kwargs):
        return request(method, args.bucket, args.region, key, access_key, secret_key, **kwargs)

    # 先检查桶，避免把桶不存在误判为目录缺失。
    status = send("HEAD", "")
    if status != 200:
        raise RuntimeError(f"Bucket 检查失败（HTTP {status}）")
    status, rename = send("GET", "", query="rename=", read_json=True)
    if status != 200 or not isinstance(rename.get("RenameEnable"), bool):
        raise RuntimeError(f"RenameObject 配置检查失败（HTTP {status}）")
    if not rename["RenameEnable"]:
        if not args.enable_rename:
            raise RuntimeError("桶未开启 RenameObject，请先开启或使用 --enable-rename")
        status = send("PUT", "", query="rename=", payload=b'{"RenameEnable":true}')
        if status != 200:
            raise RuntimeError(f"RenameObject 开启失败（HTTP {status}）；请检查权限及版本控制设置")
        status, rename = send("GET", "", query="rename=", read_json=True)
        if status != 200 or rename.get("RenameEnable") is not True:
            raise RuntimeError(f"RenameObject 开启后回查失败（HTTP {status}）")
    key = "logs/spark-events/"
    status = send("HEAD", key)
    created = False
    if status == 404 and not args.check:
        status = send("PUT", key)
        if status not in (200, 201):
            raise RuntimeError(f"目录创建失败（HTTP {status}）")
        created = True
        status = send("HEAD", key)
    if status != 200:
        raise RuntimeError(f"目录检查失败（HTTP {status}）")
    action = "已创建并回查" if created else "已确认存在"
    print(f"{action}：tos://{args.bucket}/{key}；RenameObject 已开启")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
        # 不输出请求头或凭据。
        print(f"TOS 部署准备失败：{error}", file=sys.stderr)
        sys.exit(1)
