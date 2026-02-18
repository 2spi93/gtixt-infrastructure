#!/usr/bin/env python3
import argparse
import concurrent.futures
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Iterable, List, Tuple


def fetch_json(url: str, timeout: int = 20, retries: int = 3) -> Dict[str, Any]:
    last_error: Exception | None = None
    for attempt in range(retries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "gpti-audit/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                payload = resp.read()
            return json.loads(payload.decode("utf-8"))
        except urllib.error.HTTPError as exc:
            last_error = exc
            if exc.code in (429, 500, 502, 503, 504) and attempt < retries:
                time.sleep(1.5 * (attempt + 1))
                continue
            raise
        except urllib.error.URLError as exc:
            last_error = exc
            if attempt < retries:
                time.sleep(1.0 * (attempt + 1))
                continue
            raise
    if last_error:
        raise last_error
    raise RuntimeError("fetch failed")


def is_missing(value: Any) -> bool:
    if value is None:
        return True
    if isinstance(value, str):
        return value.strip() == "" or value.strip() == "—"
    return False


def fetch_firms(base_url: str, limit: int | None = None) -> List[Dict[str, Any]]:
    all_firms: List[Dict[str, Any]] = []
    offset = 0
    page_size = 500

    while True:
        if limit is not None:
            remaining = max(limit - len(all_firms), 0)
            if remaining <= 0:
                break
            page_size = min(page_size, remaining)
        url = f"{base_url}/api/firms/?limit={page_size}&offset={offset}"
        data = fetch_json(url)
        firms = data.get("firms", [])
        if not firms:
            break
        all_firms.extend(firms)
        offset += len(firms)
        total = data.get("total") or 0
        if total and len(all_firms) >= total:
            break
    return all_firms


def audit_firm(base_url: str, firm_id: str) -> Tuple[str, Dict[str, Any] | None, str | None]:
    url = f"{base_url}/api/firm/?id={urllib.parse.quote(firm_id)}"
    try:
        data = fetch_json(url)
        firm = data.get("firm") or data
        return firm_id, firm, None
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError) as exc:
        return firm_id, None, str(exc)


def collect_missing(base_url: str, firms: Iterable[Dict[str, Any]], workers: int) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    missing: List[Dict[str, Any]] = []
    errors: List[Dict[str, Any]] = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        futures = []
        for firm in firms:
            firm_id = firm.get("firm_id") or ""
            if not firm_id:
                continue
            futures.append(executor.submit(audit_firm, base_url, str(firm_id)))

        for future in concurrent.futures.as_completed(futures):
            firm_id, firm, error = future.result()
            if error:
                errors.append({"firm_id": firm_id, "error": error})
                continue
            if not firm:
                errors.append({"firm_id": firm_id, "error": "empty_response"})
                continue

            payout_frequency = firm.get("payout_frequency")
            max_drawdown = firm.get("max_drawdown_rule") or firm.get("max_drawdown")
            daily_drawdown = firm.get("daily_drawdown_rule") or firm.get("daily_drawdown")
            jurisdiction_tier = firm.get("jurisdiction_tier")

            missing_fields = []
            if is_missing(payout_frequency):
                missing_fields.append("payout_frequency")
            if is_missing(max_drawdown):
                missing_fields.append("max_drawdown_rule")
            if is_missing(daily_drawdown):
                missing_fields.append("daily_drawdown_rule")
            if is_missing(jurisdiction_tier):
                missing_fields.append("jurisdiction_tier")

            if missing_fields:
                missing.append({
                    "firm_id": firm_id,
                    "name": firm.get("name") or firm.get("firm_name") or "",
                    "website_root": firm.get("website_root") or "",
                    "missing_fields": ",".join(missing_fields),
                    "payout_frequency": payout_frequency,
                    "max_drawdown_rule": max_drawdown,
                    "daily_drawdown_rule": daily_drawdown,
                    "jurisdiction_tier": jurisdiction_tier,
                })

    return missing, errors


def write_csv(path: str, rows: List[Dict[str, Any]]) -> None:
    headers = [
        "firm_id",
        "name",
        "website_root",
        "missing_fields",
        "payout_frequency",
        "max_drawdown_rule",
        "daily_drawdown_rule",
        "jurisdiction_tier",
    ]
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(",".join(headers) + "\n")
        for row in rows:
            values = []
            for key in headers:
                value = row.get(key, "")
                if value is None:
                    value = ""
                value = str(value).replace("\n", " ").replace("\r", " ")
                if "," in value:
                    value = '"' + value.replace('"', '""') + '"'
                values.append(value)
            handle.write(",".join(values) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit missing payout/drawdown/tier fields for firms.")
    parser.add_argument("--base-url", default="https://gtixt.com", help="Base URL for the API")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of firms to audit")
    parser.add_argument("--workers", type=int, default=10, help="Concurrent workers for /api/firm requests")
    parser.add_argument("--output", default=None, help="CSV output path")
    args = parser.parse_args()

    start = time.time()
    try:
        firms = fetch_firms(args.base_url, args.limit)
    except Exception as exc:
        print(f"[audit] failed to fetch firms: {exc}", file=sys.stderr)
        return 1

    missing, errors = collect_missing(args.base_url, firms, args.workers)
    output_path = args.output or f"/opt/gpti/tmp/missing_fields_{int(start)}.csv"
    write_csv(output_path, missing)

    duration = time.time() - start
    print("[audit] complete")
    print(f"[audit] total firms: {len(firms)}")
    print(f"[audit] missing fields: {len(missing)}")
    print(f"[audit] errors: {len(errors)}")
    print(f"[audit] output: {output_path}")
    if errors:
        print("[audit] sample errors:")
        for row in errors[:5]:
            print(f"  - {row.get('firm_id')}: {row.get('error')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
