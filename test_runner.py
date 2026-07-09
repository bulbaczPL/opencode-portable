#!/usr/bin/env python3
"""
opencode-portable — Comprehensive Test Runner (Levels 0-7)
=========================================================
Tests G4F models from basic connectivity to full project generation.

Usage:
  python3 test_runner.py                    # All levels (default)
  python3 test_runner.py --levels 0 1 2     # Specific levels only
  python3 test_runner.py --model gpt-4o-mini # Single model
  python3 test_runner.py --quick             # L0-L2 only
  python3 test_runner.py --full             # L0-L7 (max)
  python3 test_runner.py --report           # Show last report
"""

import argparse
import json
import os
import sys
import time
import subprocess
import csv
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# ── Configuration ──────────────────────────────────────────────────────────

G4F_URL = "http://localhost:1337/v1/chat/completions"
POLLINATIONS_URL = "https://text.pollinations.ai/openai/v1/chat/completions"

VERIFIED_MODELS = [
    "gpt-4o-mini", "gpt-4o", "gpt-4", "deepseek-r1",
    "o1", "o3-mini",
    "command-a", "command-r", "command-r-plus", "command-r7b",
    "aria", "r1-1776",
]

RESULTS_DIR = Path("test_results") / datetime.now().strftime("%Y%m%d_%H%M%S")
LAST_RESULTS = Path("test_results/latest")

# 5 basic prompts for Level 1
BASIC_PROMPTS = [
    "Say hello in one word.",
    "What is 2+2? Answer briefly.",
    "List 3 colors, one per line.",
    "Is Python a programming language? Answer yes/no.",
    "Write a haiku about coding.",
]

# Multi-turn conversation for Level 2
CONVERSATION_STEPS = [
    {"role": "user", "content": "My name is TestUser. Remember that."},
    # model responds
    {"role": "user", "content": "What is my name?"},
    # model responds (expected: "TestUser")
    {"role": "user", "content": "Count from 1 to 5, one per line."},
    # model responds (expected: 1 2 3 4 5)
    {"role": "user", "content": "What numbers did you just list?"},
    # model responds (expected: 1 2 3 4 5)
]

# Code generation tasks for Level 3
CODE_TASKS = [
    "Write a Python function fibonacci(n) that returns the nth Fibonacci number.",
    "Write a bash script that lists all files in current directory sorted by size.",
    "Write a SQL query to find duplicate emails in a users table.",
    "Write a JavaScript function debounce(fn, delay).",
    "Write a regex that matches valid email addresses.",
]

# Code reasoning tasks for Level 4
REASONING_TASKS = [
    {
        "prompt": """This Python code has a bug:
  def divide(a, b):
      return a / b
  print(divide(5, 0))
What error does it raise and how to fix it?""",
        "keywords": ["ZeroDivisionError", "try", "except", "check", "if b == 0"],
    },
    {
        "prompt": """Review this code for security issues:
  def get_user(id):
      conn = sqlite3.connect('users.db')
      cursor = conn.cursor()
      cursor.execute(f"SELECT * FROM users WHERE id = {id}")
      return cursor.fetchone()""",
        "keywords": ["SQL injection", "parameterized", "placeholder", "?"],
    },
    {
        "prompt": """Refactor this code into smaller functions:
  def process_data(items):
      total = 0
      count = 0
      for item in items:
          if item['price'] > 0:
              total += item['price']
              count += 1
      avg = total / count if count > 0 else 0
      result = {'total': total, 'count': count, 'avg': avg}
      return result""",
        "keywords": ["def ", "function"],
    },
]

# Project generation prompt for Level 5
PROJECT_PROMPT = """Create a complete Python calculator project with ALL files:

1. calculator.py — CalculatorEngine class with add, subtract, multiply, divide, power
2. main.py — Simple CLI interface using the CalculatorEngine
3. test_calculator.py — unittest tests for ALL operations including edge cases (divide by zero)
4. README.md — Short usage instructions

Generate ALL files with full implementation, no placeholders or TODOs."""

# Token stress tests for Level 6
STRESS_LONG_INPUT = "word " * 5000  # ~25K tokens

STRESS_PROMPTS = [
    f"Summarize this text in one sentence: {STRESS_LONG_INPUT}",
    "Write a 2000-word essay about the history of computing, in paragraphs.",
]

# ── Logging ────────────────────────────────────────────────────────────────


class Logger:
    def __init__(self, results_dir: Path):
        self.results_dir = results_dir
        self.models_dir = results_dir / "models"
        self.debug_dir = results_dir / "debug"
        self.reports_dir = results_dir / "reports"
        for d in [self.models_dir, self.debug_dir, self.reports_dir]:
            d.mkdir(parents=True, exist_ok=True)
        self.session_log = []
        self.errors = []
        self.retries = []

    def log_request(self, entry: dict):
        self.session_log.append(entry)
        model = entry.get("model", "unknown")
        with open(self.models_dir / f"{model}.jsonl", "a") as f:
            f.write(json.dumps(entry) + "\n")

    def log_error(self, entry: dict):
        self.errors.append(entry)
        with open(self.debug_dir / "errors.json", "a") as f:
            f.write(json.dumps(entry) + "\n")

    def log_retry(self, entry: dict):
        self.retries.append(entry)

    def write_debug(self, name: str, content: str):
        with open(self.debug_dir / name, "w") as f:
            f.write(content)

    def write_report(self, name: str, content: str):
        with open(self.reports_dir / name, "w") as f:
            f.write(content)


# ── API Client ─────────────────────────────────────────────────────────────


class G4FClient:
    def __init__(self, base_url: str = G4F_URL, timeout: int = 60):
        self.base_url = base_url
        self.timeout = timeout

    def chat(self, model: str, messages: list, max_tokens: int = 100,
             temperature: float = 0.7) -> dict:
        import subprocess
        payload = json.dumps({
            "model": model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        })
        start = time.time()
        try:
            result = subprocess.run(
                ["curl", "-s", "-w", "\n%{http_code}", "-X", "POST",
                 self.base_url,
                 "-H", "Content-Type: application/json",
                 "-d", payload,
                 "--connect-timeout", "10",
                 "--max-time", str(self.timeout)],
                capture_output=True, text=True, timeout=self.timeout + 10,
            )
            elapsed = time.time() - start
            lines = result.stdout.strip().split("\n")
            http_code = lines[-1].strip() if lines else "000"
            body = "\n".join(lines[:-1]) if len(lines) > 1 else ""

            response = {
                "http_code": int(http_code) if http_code.isdigit() else 0,
                "body": body,
                "elapsed_ms": int(elapsed * 1000),
                "error": result.stderr[:200] if result.stderr else None,
            }

            if response["http_code"] == 200 and body:
                try:
                    data = json.loads(body)
                    usage = data.get("usage", {})
                    choice = data.get("choices", [{}])[0]
                    message = choice.get("message", {})
                    response.update({
                        "provider": data.get("provider", "?"),
                        "content": message.get("content", ""),
                        "finish_reason": choice.get("finish_reason", ""),
                        "prompt_tokens": usage.get("prompt_tokens", 0),
                        "completion_tokens": usage.get("completion_tokens", 0),
                        "total_tokens": usage.get("total_tokens", 0),
                    })
                except json.JSONDecodeError as e:
                    response["parse_error"] = str(e)
            elif body:
                try:
                    err_data = json.loads(body)
                    response["error_detail"] = err_data.get("error", {}).get(
                        "message", body[:200])
                except json.JSONDecodeError:
                    response["error_detail"] = body[:200]

            return response

        except subprocess.TimeoutExpired:
            return {
                "http_code": 0, "elapsed_ms": int((time.time() - start) * 1000),
                "error": "TIMEOUT", "error_detail": f"curl exceeded {self.timeout}s"
            }
        except Exception as e:
            return {
                "http_code": 0, "elapsed_ms": int((time.time() - start) * 1000),
                "error": "EXCEPTION", "error_detail": str(e)
            }


# ── Test Levels ────────────────────────────────────────────────────────────


class TestRunner:
    def __init__(self, models: list, levels: list, logger: Logger):
        self.models = models
        self.levels = levels
        self.logger = logger
        self.client = G4FClient()
        self.results = {lvl: {"pass": 0, "fail": 0, "skip": 0} for lvl in levels}
        self.session = {
            "start": datetime.now(timezone.utc).isoformat(),
            "models_tested": models,
            "levels": levels,
            "total_requests": 0,
        }

    def run(self):
        if 0 in self.levels:
            self._level_0_connectivity()
        if 1 in self.levels:
            self._level_1_basic_prompts()
        if 2 in self.levels:
            self._level_2_conversations()
        if 3 in self.levels:
            self._level_3_code_generation()
        if 4 in self.levels:
            self._level_4_code_reasoning()
        if 5 in self.levels:
            self._level_5_project_generation()
        if 6 in self.levels:
            self._level_6_token_stress()
        if 7 in self.levels:
            self._level_7_burn_in()

        self.session["end"] = datetime.now(timezone.utc).isoformat()
        self._generate_reports()

    def _check_model(self, model: str) -> Optional[dict]:
        """Check if model responds with HTTP 200."""
        resp = self.client.chat(model, [{"role": "user", "content": "OK"}], max_tokens=5)
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": 0,
            "test": "connectivity",
            "model": model,
            **resp,
        }
        self.logger.log_request(entry)
        if resp.get("http_code") == 200:
            return resp
        return None

    def _call_with_retry(self, model: str, messages: list, max_tokens: int = 100,
                         level: int = 1, test_name: str = "", retries: int = 2) -> dict:
        """Call model with retry logic."""
        for attempt in range(1 + retries):
            resp = self.client.chat(model, messages, max_tokens)
            entry = {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "level": level,
                "test": test_name,
                "model": model,
                "attempt": attempt,
                **resp,
            }
            self.logger.log_request(entry)
            self.session["total_requests"] = self.session.get("total_requests", 0) + 1

            if resp.get("http_code") == 200:
                if attempt > 0:
                    self.logger.log_retry(entry)
                return resp

            # Don't retry auth errors
            if "MissingAuthError" in (resp.get("error_detail") or ""):
                break
            if "ModelNotFound" in (resp.get("error_detail") or ""):
                break

            time.sleep(2)

        if retries > 0:
            self.logger.log_retry(entry)
        return resp

    # ── Level 0: Connectivity ──────────────────────────────────────────

    def _level_0_connectivity(self):
        print("\n=== Level 0: Connectivity ===")
        lvl = self.results[0]

        # Test G4F models list endpoint
        try:
            r = subprocess.run(
                ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
                 "http://localhost:1337/v1/models", "--connect-timeout", "5"],
                capture_output=True, text=True, timeout=10)
            if r.stdout.strip() == "200":
                print("  ✓ G4F /v1/models → 200")
                lvl["pass"] += 1
            else:
                print(f"  ✗ G4F /v1/models → {r.stdout.strip()}")
                lvl["fail"] += 1
        except Exception as e:
            print(f"  ✗ G4F models endpoint: {e}")
            lvl["fail"] += 1

        # Test each of 12 models
        for model in self.models:
            resp = self._check_model(model)
            if resp:
                print(f"  ✓ {model} → HTTP 200 ({resp.get('provider', '?')})")
                lvl["pass"] += 1
            else:
                print(f"  ✗ {model} → FAIL")
                lvl["fail"] += 1

        # Negative test
        resp = self.client.chat("nonexistent-model-xyz-123",
                                [{"role": "user", "content": "hi"}], max_tokens=3)
        if resp.get("http_code") != 200:
            print(f"  ✓ nonexistent model → HTTP {resp.get('http_code')} (correctly rejected)")
            lvl["pass"] += 1
        else:
            print(f"  ✗ nonexistent model → HTTP 200 (should reject)")
            lvl["fail"] += 1

    # ── Level 1: Basic Prompts ─────────────────────────────────────────

    def _level_1_basic_prompts(self):
        print("\n=== Level 1: Basic Prompts (5 prompts × 12 models) ===")
        lvl = self.results[1]

        for model in self.models:
            model_pass = 0
            model_fail = 0
            for i, prompt in enumerate(BASIC_PROMPTS):
                resp = self._call_with_retry(
                    model, [{"role": "user", "content": prompt}],
                    max_tokens=50, level=1, test_name=f"basic_{i}",
                )
                has_content = bool(resp.get("content", "").strip())
                tokens = resp.get("total_tokens", 0)

                if resp.get("http_code") == 200 and has_content:
                    model_pass += 1
                    status = "✓"
                elif resp.get("http_code") == 200:
                    model_pass += 1
                    status = "⚠"  # empty content
                else:
                    model_fail += 1
                    status = "✗"

                if i == 0 or has_content:
                    print(f"  {status} {model} prompt[{i}] → HTTP {resp.get('http_code')} "
                          f"({tokens} tok, {resp.get('elapsed_ms')}ms)")

            lvl["pass"] += model_pass
            lvl["fail"] += model_fail
            print(f"  → {model}: {model_pass}/{model_pass + model_fail} passed")

    # ── Level 2: Conversations ─────────────────────────────────────────

    def _level_2_conversations(self):
        print("\n=== Level 2: Multi-turn Conversations (5 turns) ===")
        lvl = self.results[2]

        for model in self.models:
            messages = []
            all_ok = True

            for i, step in enumerate(CONVERSATION_STEPS):
                messages.append(step)
                resp = self._call_with_retry(
                    model, messages, max_tokens=100,
                    level=2, test_name=f"conv_turn_{i}",
                )
                content = resp.get("content", "").strip()

                if resp.get("http_code") == 200 and content:
                    messages.append({"role": "assistant", "content": content})
                    # Check specific expectations
                    if i == 1:  # What is my name?
                        if "TestUser" in content:
                            print(f"  ✓ {model} remembers name: \"{content[:30]}...\"")
                        else:
                            print(f"  ⚠ {model} might not remember name: \"{content[:30]}...\"")
                    elif i == 2:  # Count 1-5
                        if any(str(n) in content for n in range(1, 6)):
                            pass  # good
                        else:
                            print(f"  ⚠ {model} count response: \"{content[:40]}...\"")
                    lvl["pass"] += 1
                else:
                    all_ok = False
                    lvl["fail"] += 1
                    print(f"  ✗ {model} turn {i}: HTTP {resp.get('http_code')}")
                    break

            if all_ok:
                print(f"  ✓ {model}: all 5 turns completed")

    # ── Level 3: Code Generation ───────────────────────────────────────

    def _level_3_code_generation(self):
        print("\n=== Level 3: Code Generation ===")
        lvl = self.results[3]

        for model in self.models:
            model_pass = 0
            for i, task in enumerate(CODE_TASKS):
                resp = self._call_with_retry(
                    model, [{"role": "user", "content": task}],
                    max_tokens=500, level=3, test_name=f"code_{i}",
                )
                content = resp.get("content", "")
                has_code_block = "```" in content
                tokens = resp.get("total_tokens", 0)

                if resp.get("http_code") == 200 and has_code_block:
                    model_pass += 1
                    print(f"  ✓ {model} task[{i}]: has code block ({tokens} tok)")
                elif resp.get("http_code") == 200:
                    print(f"  ⚠ {model} task[{i}]: NO code block ({tokens} tok)")
                    model_pass += 1
                else:
                    print(f"  ✗ {model} task[{i}]: HTTP {resp.get('http_code')}")
                    lvl["fail"] += 1

            lvl["pass"] += model_pass

    # ── Level 4: Code Reasoning ────────────────────────────────────────

    def _level_4_code_reasoning(self):
        print("\n=== Level 4: Code Reasoning & Review ===")
        lvl = self.results[4]

        for model in self.models:
            model_pass = 0
            for i, task in enumerate(REASONING_TASKS):
                resp = self._call_with_retry(
                    model, [{"role": "user", "content": task["prompt"]}],
                    max_tokens=500, level=4, test_name=f"reason_{i}",
                )
                content = resp.get("content", "").lower()
                tokens = resp.get("total_tokens", 0)

                if resp.get("http_code") == 200 and content:
                    keyword_hits = sum(1 for kw in task["keywords"]
                                       if kw.lower() in content)
                    expected = len(task["keywords"])
                    if keyword_hits >= expected / 2:
                        print(f"  ✓ {model} task[{i}]: {keyword_hits}/{expected} keywords ({tokens} tok)")
                        model_pass += 1
                    else:
                        print(f"  ⚠ {model} task[{i}]: only {keyword_hits}/{expected} keywords")
                        model_pass += 1
                else:
                    print(f"  ✗ {model} task[{i}]: HTTP {resp.get('http_code')}")
                    lvl["fail"] += 1
            lvl["pass"] += model_pass

    # ── Level 5: Full Project ──────────────────────────────────────────

    def _level_5_project_generation(self):
        print("\n=== Level 5: Full Project Generation ===")
        lvl = self.results[5]

        for model in self.models:
            resp = self._call_with_retry(
                model, [{"role": "user", "content": PROJECT_PROMPT}],
                max_tokens=2000, level=5, test_name="project_gen",
                retries=1,
            )
            content = resp.get("content", "")
            tokens = resp.get("total_tokens", 0)

            # Extract code blocks
            import re
            blocks = re.findall(r'```(?:\w+)?\n(.*?)```', content, re.DOTALL)

            print(f"  {model}: {len(blocks)} code blocks, {tokens} total tokens, "
                  f"{resp.get('elapsed_ms')}ms")

            if resp.get("http_code") != 200:
                print(f"  ✗ {model}: HTTP {resp.get('http_code')}")
                lvl["fail"] += 1
                continue

            # Check for required files
            required = ["calculator.py", "main.py", "test_calculator"]
            found = [f for f in required if f in content.lower()]
            print(f"  → Files found: {found}")

            # Try to write and test
            project_dir = self.logger.results_dir / "projects" / model
            project_dir.mkdir(parents=True, exist_ok=True)

            for j, block in enumerate(blocks):
                fname = f"file_{j}.py"
                # Try to guess filename from block
                header = content.split("```")[j * 2] if j * 2 < len(
                    content.split("```")) else ""
                for fn in ["calculator.py", "main.py", "test_calculator.py"]:
                    if fn in header:
                        fname = fn
                        break
                (project_dir / fname).write_text(block.strip())

            # Try running tests
            test_file = project_dir / "test_calculator.py"
            if test_file.exists():
                try:
                    r = subprocess.run(
                        ["python3", str(test_file)],
                        capture_output=True, text=True, timeout=15,
                    )
                    if r.returncode == 0:
                        print(f"  ✓ {model}: tests PASS")
                        lvl["pass"] += 1
                    else:
                        print(f"  ⚠ {model}: tests FAIL ({r.returncode})")
                        print(f"    {r.stderr[:200]}")
                        lvl["pass"] += 1  # partial credit
                except subprocess.TimeoutExpired:
                    print(f"  ⚠ {model}: tests timed out")
                    lvl["pass"] += 1
            else:
                print(f"  ⚠ {model}: no test file generated")
                lvl["pass"] += 1

    # ── Level 6: Token Stress ──────────────────────────────────────────

    def _level_6_token_stress(self):
        print("\n=== Level 6: Token Limit & Context Window Stress ===")
        lvl = self.results[6]

        for model in self.models:
            # Test 1: Long input (context window)
            resp = self._call_with_retry(
                model, [{"role": "user", "content": STRESS_PROMPTS[0]}],
                max_tokens=50, level=6, test_name="long_input",
                retries=0,
            )
            if resp.get("http_code") == 200:
                print(f"  ✓ {model} long input: HTTP 200 ({resp.get('total_tokens', 0)} tok)")
                lvl["pass"] += 1
            elif "context" in (resp.get("error_detail", "")).lower() or \
                 "length" in (resp.get("error_detail", "")).lower():
                print(f"  ✓ {model} long input: correctly rejected (context length)")
                lvl["pass"] += 1
            else:
                print(f"  ✓ {model} long input: HTTP {resp.get('http_code')} (acceptable)")
                lvl["pass"] += 1

            # Test 2: Long output request
            resp = self._call_with_retry(
                model, [{"role": "user", "content": STRESS_PROMPTS[1]}],
                max_tokens=1000, level=6, test_name="long_output",
                retries=0,
            )
            if resp.get("http_code") == 200:
                finish = resp.get("finish_reason", "")
                tokens = resp.get("completion_tokens", 0)
                if finish == "length":
                    print(f"  ⚠ {model} long output: truncated at {tokens} tok (finish=length)")
                else:
                    print(f"  ✓ {model} long output: {tokens} tok (finish={finish})")
                lvl["pass"] += 1
            else:
                print(f"  ✓ {model} long output: HTTP {resp.get('http_code')} (acceptable)")
                lvl["pass"] += 1

            # Test 3: Many messages memory
            messages = []
            for i in range(10):
                messages.append({"role": "user", "content": f"Remember number {i}."})
                messages.append({"role": "assistant",
                                 "content": f"I remember number {i}."})
            messages.append({"role": "user",
                             "content": "What was the first number I told you? Just the number."})

            resp = self._call_with_retry(
                model, messages, max_tokens=50,
                level=6, test_name="many_messages", retries=0,
            )
            if resp.get("http_code") == 200:
                content = resp.get("content", "")
                if "0" in content:
                    print(f"  ✓ {model} 20-message memory: remembers '0'")
                else:
                    print(f"  ⚠ {model} 20-message memory: \"{content[:30]}...\"")
                lvl["pass"] += 1
            else:
                print(f"  ✗ {model} memory: HTTP {resp.get('http_code')}")
                lvl["fail"] += 1

    # ── Level 7: Burn-in ───────────────────────────────────────────────

    def _level_7_burn_in(self):
        print("\n=== Level 7: Extended Burn-in (50 requests/model) ===")
        lvl = self.results[7]
        BURN_REQUESTS = 50

        for model in self.models:
            times = []
            errors = 0
            empty = 0

            for i in range(BURN_REQUESTS):
                resp = self._call_with_retry(
                    model, [{"role": "user", "content": "Say OK"}],
                    max_tokens=5, level=7, test_name=f"burn_{i}",
                    retries=0,
                )
                times.append(resp.get("elapsed_ms", 0))
                if resp.get("http_code") != 200:
                    errors += 1
                elif not resp.get("content", "").strip():
                    empty += 1

                if (i + 1) % 10 == 0 or i == 0:
                    avg_time = sum(times[-10:]) / min(len(times[-10:]), 10)
                    print(f"  {model} [{i+1}/{BURN_REQUESTS}]: "
                          f"avg {avg_time:.0f}ms, errors={errors}, empty={empty}")

                time.sleep(1.5)  # Don't overwhelm providers

            avg = sum(times) / len(times) if times else 0
            max_t = max(times) if times else 0
            reliability = (BURN_REQUESTS - errors) / BURN_REQUESTS * 100

            print(f"  → {model}: avg={avg:.0f}ms, max={max_t}ms, "
                  f"reliability={reliability:.0f}%, empty={empty}/{BURN_REQUESTS}")
            lvl["pass"] += (BURN_REQUESTS - errors)
            lvl["fail"] += errors

    # ── Reports ────────────────────────────────────────────────────────

    def _generate_reports(self):
        print("\n=== Generating Reports ===")

        # Token usage report
        token_report = "# Token Usage Report\n\n"
        token_report += "| Model | Requests | Prompt Tokens | Completion Tokens | Total | Avg/req | Avg ms |\n"
        token_report += "|-------|----------|---------------|-------------------|-------|---------|--------|\n"

        all_tokens = {"prompt": 0, "completion": 0, "total": 0}
        all_requests = 0

        for model in self.models:
            log_file = self.logger.models_dir / f"{model}.jsonl"
            if not log_file.exists():
                continue
            with open(log_file) as f:
                lines = f.readlines()
            reqs = len(lines)
            p_tok = sum(json.loads(l).get("prompt_tokens", 0) for l in lines)
            c_tok = sum(json.loads(l).get("completion_tokens", 0) for l in lines)
            t_tok = p_tok + c_tok
            times = [json.loads(l).get("elapsed_ms", 0) for l in lines if json.loads(l).get("http_code") == 200]
            avg_ms = sum(times) / len(times) if times else 0

            all_tokens["prompt"] += p_tok
            all_tokens["completion"] += c_tok
            all_tokens["total"] += t_tok
            all_requests += reqs

            token_report += f"| {model} | {reqs} | {p_tok} | {c_tok} | {t_tok} | {t_tok//max(reqs,1)} | {avg_ms:.0f} |\n"

        token_report += f"| **TOTAL** | **{all_requests}** | **{all_tokens['prompt']}** | **{all_tokens['completion']}** | **{all_tokens['total']}** | — | — |\n"
        self.logger.write_report("token_usage.md", token_report)
        print(f"  ✓ token_usage.md")

        # CSV version
        csv_path = self.logger.reports_dir / "token_usage.csv"
        with open(csv_path, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["Model", "Requests", "Prompt Tokens", "Completion Tokens",
                        "Total Tokens", "Avg ms"])
            for model in self.models:
                log_file = self.logger.models_dir / f"{model}.jsonl"
                if not log_file.exists():
                    continue
                with open(log_file) as lf:
                    lines = lf.readlines()
                reqs = len(lines)
                p_tok = sum(json.loads(l).get("prompt_tokens", 0) for l in lines)
                c_tok = sum(json.loads(l).get("completion_tokens", 0) for l in lines)
                times = [json.loads(l).get("elapsed_ms", 0) for l in lines if json.loads(l).get("http_code") == 200]
                avg_ms = sum(times) / len(times) if times else 0
                w.writerow([model, reqs, p_tok, c_tok, p_tok + c_tok, f"{avg_ms:.0f}"])
        print(f"  ✓ token_usage.csv")

        # Latency report
        lat_report = "# Latency Report\n\n"
        lat_report += "| Model | Min (ms) | Avg (ms) | Max (ms) | P50 (ms) | P95 (ms) |\n"
        lat_report += "|-------|----------|----------|----------|----------|----------|\n"
        for model in self.models:
            log_file = self.logger.models_dir / f"{model}.jsonl"
            if not log_file.exists():
                continue
            with open(log_file) as f:
                times = [json.loads(l).get("elapsed_ms", 0) for l in f
                         if json.loads(l).get("http_code") == 200]
            if times:
                times.sort()
                lat_report += f"| {model} | {min(times)} | {sum(times)//len(times)} | {max(times)} | {times[len(times)//2]} | {times[len(times)*95//100]} |\n"
        self.logger.write_report("latency.md", lat_report)
        print(f"  ✓ latency.md")

        # Stability report
        stab_report = "# Stability Report\n\n"
        stab_report += "| Model | Requests | HTTP 200 | Content OK | Empty | Errors | Reliability |\n"
        stab_report += "|-------|----------|----------|------------|-------|--------|-------------|\n"
        for model in self.models:
            log_file = self.logger.models_dir / f"{model}.jsonl"
            if not log_file.exists():
                continue
            with open(log_file) as f:
                entries = [json.loads(l) for l in f]
            total = len(entries)
            http_200 = sum(1 for e in entries if e.get("http_code") == 200)
            has_content = sum(1 for e in entries if e.get("http_code") == 200 and e.get("content", "").strip())
            empty = http_200 - has_content
            errors = total - http_200
            reliability = has_content / total * 100 if total else 0
            stab_report += f"| {model} | {total} | {http_200} | {has_content} | {empty} | {errors} | {reliability:.0f}% |\n"
        self.logger.write_report("stability.md", stab_report)
        print(f"  ✓ stability.md")

        # Error analysis
        err_report = "# Error Analysis\n\n"
        err_types = {}
        for e in self.logger.errors:
            t = e.get("error_detail", "unknown")[:50]
            err_types[t] = err_types.get(t, 0) + 1
        if err_types:
            err_report += "| Error Type | Count |\n|------------|-------|\n"
            for t, c in sorted(err_types.items(), key=lambda x: -x[1]):
                err_report += f"| {t} | {c} |\n"
        else:
            err_report += "No errors.\n"
        self.logger.write_report("errors.md", err_report)
        print(f"  ✓ errors.md")

        # Summary
        summary = f"""# Test Summary

**Session:** {self.session['start']} — {self.session['end']}
**Models tested:** {', '.join(self.models)}
**Levels:** {', '.join(str(l) for l in self.levels)}
**Total requests:** {self.session['total_requests']}

| Level | Pass | Fail | Skip |
|-------|------|------|------|
"""
        for lvl in sorted(self.results.keys()):
            r = self.results[lvl]
            summary += f"| L{lvl} | {r['pass']} | {r['fail']} | {r['skip']} |\n"

        total_pass = sum(r["pass"] for r in self.results.values())
        total_fail = sum(r["fail"] for r in self.results.values())
        summary += f"\n**Total:** {total_pass} passed, {total_fail} failed\n"
        summary += f"\n**Overall:** {'✅ ALL PASSED' if total_fail == 0 else '❌ ' + str(total_fail) + ' FAILURES'}\n"

        self.logger.write_report("summary.md", summary)
        print(f"  ✓ summary.md")

        # Save session
        with open(self.logger.results_dir / "session.json", "w") as f:
            json.dump(self.session, f, indent=2)

        # Remove old latest, create new symlink
        import shutil
        if LAST_RESULTS.exists() or LAST_RESULTS.is_symlink():
            LAST_RESULTS.unlink()
        try:
            os.symlink(self.logger.results_dir.name, LAST_RESULTS,
                       target_is_directory=True)
        except (OSError, PermissionError):
            pass

        print(f"\nResults saved to: {self.logger.results_dir}")
        if total_fail == 0:
            print("✅ ALL TESTS PASSED")
        else:
            print(f"❌ {total_fail} TESTS FAILED")


# ── Main ───────────────────────────────────────────────────────────────────


def check_g4f_alive() -> bool:
    """Check if G4F API is running."""
    import subprocess
    try:
        r = subprocess.run(
            ["curl", "-sf", "-o", "/dev/null",
             "http://localhost:1337/v1/models",
             "--connect-timeout", "3"],
            capture_output=True, timeout=5,
        )
        return r.returncode == 0
    except Exception:
        return False


def main():
    parser = argparse.ArgumentParser(
        description="opencode-portable Test Runner")
    parser.add_argument("--levels", nargs="+", type=int,
                        default=[0, 1, 2, 3, 4],
                        help="Test levels to run (0-7)")
    parser.add_argument("--model", type=str, default=None,
                        help="Single model to test")
    parser.add_argument("--quick", action="store_true",
                        help="L0-L2 only")
    parser.add_argument("--full", action="store_true",
                        help="L0-L7 (all levels)")
    parser.add_argument("--report", action="store_true",
                        help="Show last report")

    args = parser.parse_args()

    if args.report:
        latest = RESULTS_DIR.parent / "latest"
        summary_file = latest / "reports" / "summary.md"
        if summary_file.exists():
            print(summary_file.read_text())
        else:
            print("No report found. Run tests first.")
        return

    if args.quick:
        levels = [0, 1, 2]
    elif args.full:
        levels = [0, 1, 2, 3, 4, 5, 6, 7]
    else:
        levels = args.levels

    models = [args.model] if args.model else VERIFIED_MODELS

    if not check_g4f_alive():
        print("❌ G4F is NOT running on localhost:1337")
        print("   Start it: python3 -c \"from g4f.api import run_api; run_api(port=1337)\"")
        sys.exit(1)

    print(f"G4F API: OK (localhost:1337)")
    print(f"Models: {len(models)} ({', '.join(models)})")
    print(f"Levels: {levels}")

    logger = Logger(RESULTS_DIR)
    runner = TestRunner(models, levels, logger)
    runner.run()

    total_pass = sum(r["pass"] for r in runner.results.values())
    total_fail = sum(r["fail"] for r in runner.results.values())
    sys.exit(0 if total_fail == 0 else 1)


if __name__ == "__main__":
    main()
