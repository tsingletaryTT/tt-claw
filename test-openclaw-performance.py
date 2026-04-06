#!/usr/bin/env python3
"""
OpenClaw Performance Test Suite
Tests command following, tool usage, and creative thinking with current model
"""

import asyncio
import websockets
import json
import time
from datetime import datetime
from typing import Dict, List, Any

# Configuration
GATEWAY_URL = "ws://127.0.0.1:18789"
TEST_AGENT = "main"
TIMEOUT = 60  # seconds per test

# Test categories and prompts
TESTS = {
    "basic_commands": [
        {
            "name": "Simple question",
            "prompt": "What is 2+2?",
            "expected": "should give correct answer (4)",
            "eval_criteria": ["correctness", "brevity"]
        },
        {
            "name": "Multi-step instruction",
            "prompt": "List three colors, then tell me which one is your favorite and why.",
            "expected": "should list colors and pick one with reasoning",
            "eval_criteria": ["completeness", "reasoning"]
        },
        {
            "name": "Context retention",
            "prompt": "My name is Alex. What's my name?",
            "expected": "should remember and respond with 'Alex'",
            "eval_criteria": ["memory", "accuracy"]
        },
    ],

    "tool_usage": [
        {
            "name": "Memory search - TT hardware",
            "prompt": "Search your memory for information about Tenstorrent hardware and tell me what you find.",
            "expected": "should use memory_search tool and cite sources",
            "eval_criteria": ["tool_use", "citations", "relevance"]
        },
        {
            "name": "Dice roll",
            "prompt": "Roll a 20-sided die for me.",
            "expected": "should use dice tool and show result",
            "eval_criteria": ["tool_use", "clarity"]
        },
        {
            "name": "Information synthesis",
            "prompt": "What is METALIUM? Search your memory if needed.",
            "expected": "should search memory and synthesize answer",
            "eval_criteria": ["tool_use", "synthesis", "accuracy"]
        },
    ],

    "creative_thinking": [
        {
            "name": "Story beginning",
            "prompt": "You are a dungeon master. Start an adventure in a mysterious castle.",
            "expected": "should create atmospheric, engaging opening",
            "eval_criteria": ["creativity", "atmosphere", "engagement"]
        },
        {
            "name": "Problem solving",
            "prompt": "I'm in a room with a locked door, a key on the ceiling, and a table. How do I escape?",
            "expected": "should provide logical solution (use table to reach key)",
            "eval_criteria": ["logic", "creativity", "clarity"]
        },
        {
            "name": "Technical explanation",
            "prompt": "Explain how a CPU cache works to a 10-year-old.",
            "expected": "should use simple analogies and be clear",
            "eval_criteria": ["clarity", "analogies", "age_appropriate"]
        },
        {
            "name": "Poetic description",
            "prompt": "Describe a Tenstorrent chip as if it were a magical realm.",
            "expected": "should be creative and poetic while accurate",
            "eval_criteria": ["creativity", "imagery", "accuracy"]
        },
    ],

    "context_and_reasoning": [
        {
            "name": "Chain of thought",
            "prompt": "If a train travels 60 miles per hour for 2.5 hours, how far does it go? Show your work.",
            "expected": "should show calculation steps",
            "eval_criteria": ["reasoning", "step_by_step", "accuracy"]
        },
        {
            "name": "Context integration",
            "prompt": "Based on our conversation so far, what topics have we discussed?",
            "expected": "should summarize previous test questions",
            "eval_criteria": ["memory", "summarization", "accuracy"]
        },
    ]
}

class OpenClawTester:
    def __init__(self):
        self.ws = None
        self.results = []
        self.start_time = None

    async def connect(self):
        """Connect to OpenClaw gateway"""
        try:
            self.ws = await websockets.connect(GATEWAY_URL)
            print(f"✓ Connected to OpenClaw gateway at {GATEWAY_URL}")
            return True
        except Exception as e:
            print(f"✗ Failed to connect: {e}")
            return False

    async def send_message(self, message: str, agent: str = TEST_AGENT) -> Dict[str, Any]:
        """Send message and get response"""
        request = {
            "type": "agent_message",
            "agent": agent,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }

        await self.ws.send(json.dumps(request))

        # Wait for response
        try:
            response_raw = await asyncio.wait_for(self.ws.recv(), timeout=TIMEOUT)
            response = json.loads(response_raw)
            return response
        except asyncio.TimeoutError:
            return {"error": "timeout", "message": f"No response after {TIMEOUT}s"}
        except Exception as e:
            return {"error": "exception", "message": str(e)}

    async def run_test(self, category: str, test: Dict[str, Any]) -> Dict[str, Any]:
        """Run a single test"""
        print(f"\n  Testing: {test['name']}")
        print(f"    Prompt: {test['prompt'][:60]}...")

        start = time.time()
        response = await self.send_message(test['prompt'])
        elapsed = time.time() - start

        result = {
            "category": category,
            "test_name": test['name'],
            "prompt": test['prompt'],
            "expected": test['expected'],
            "eval_criteria": test['eval_criteria'],
            "response": response,
            "elapsed_time": elapsed,
            "timestamp": datetime.now().isoformat()
        }

        # Extract response text
        if "error" in response:
            result["response_text"] = f"ERROR: {response.get('message', 'unknown')}"
            result["success"] = False
        else:
            # OpenClaw responses vary, try to extract message
            result["response_text"] = self._extract_response_text(response)
            result["success"] = True

        print(f"    Response time: {elapsed:.2f}s")
        print(f"    Response: {result['response_text'][:100]}...")

        return result

    def _extract_response_text(self, response: Dict) -> str:
        """Extract response text from OpenClaw response"""
        # Try various response formats
        if isinstance(response, dict):
            if "content" in response:
                return response["content"]
            elif "message" in response:
                return response["message"]
            elif "text" in response:
                return response["text"]
            elif "response" in response:
                return str(response["response"])
        return str(response)

    async def run_all_tests(self):
        """Run all test categories"""
        self.start_time = time.time()

        for category, tests in TESTS.items():
            print(f"\n{'='*60}")
            print(f"Category: {category.upper().replace('_', ' ')}")
            print(f"{'='*60}")

            for test in tests:
                result = await self.run_test(category, test)
                self.results.append(result)

                # Small delay between tests
                await asyncio.sleep(1)

        total_time = time.time() - self.start_time
        print(f"\n{'='*60}")
        print(f"All tests completed in {total_time:.2f}s")
        print(f"{'='*60}")

    def generate_report(self) -> str:
        """Generate performance report"""
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("OPENCLAW PERFORMANCE REPORT")
        report_lines.append(f"Model: Llama-3.1-8B-Instruct")
        report_lines.append(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report_lines.append(f"Total tests: {len(self.results)}")
        report_lines.append("=" * 80)

        # Overall stats
        successful = sum(1 for r in self.results if r.get('success', False))
        failed = len(self.results) - successful
        avg_time = sum(r.get('elapsed_time', 0) for r in self.results) / len(self.results)

        report_lines.append("\nOVERALL STATISTICS:")
        report_lines.append(f"  Successful: {successful}/{len(self.results)} ({successful/len(self.results)*100:.1f}%)")
        report_lines.append(f"  Failed: {failed}")
        report_lines.append(f"  Average response time: {avg_time:.2f}s")

        # Category breakdown
        categories = {}
        for result in self.results:
            cat = result['category']
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(result)

        report_lines.append("\n" + "=" * 80)
        report_lines.append("CATEGORY BREAKDOWN:")
        report_lines.append("=" * 80)

        for category, results in categories.items():
            report_lines.append(f"\n{category.upper().replace('_', ' ')}:")
            report_lines.append("-" * 80)

            for result in results:
                success_icon = "✓" if result.get('success', False) else "✗"
                report_lines.append(f"\n  {success_icon} {result['test_name']}")
                report_lines.append(f"     Prompt: {result['prompt']}")
                report_lines.append(f"     Expected: {result['expected']}")
                report_lines.append(f"     Time: {result['elapsed_time']:.2f}s")
                report_lines.append(f"     Criteria: {', '.join(result['eval_criteria'])}")
                report_lines.append(f"\n     Response ({len(result['response_text'])} chars):")

                # Show response (truncated if long)
                response_preview = result['response_text']
                if len(response_preview) > 300:
                    response_preview = response_preview[:300] + "..."

                for line in response_preview.split('\n'):
                    report_lines.append(f"       {line}")

                report_lines.append("")

        # Manual evaluation guide
        report_lines.append("\n" + "=" * 80)
        report_lines.append("MANUAL EVALUATION GUIDE:")
        report_lines.append("=" * 80)
        report_lines.append("\nFor each test, evaluate:")
        report_lines.append("  1. Did it follow instructions correctly?")
        report_lines.append("  2. Did it use tools when expected?")
        report_lines.append("  3. Was the response creative/engaging?")
        report_lines.append("  4. Did it provide citations when using memory?")
        report_lines.append("  5. Was reasoning clear and logical?")
        report_lines.append("  6. Did it maintain context across tests?")

        return "\n".join(report_lines)

    async def close(self):
        """Close connection"""
        if self.ws:
            await self.ws.close()

async def main():
    print("OpenClaw Performance Test Suite")
    print("Testing: Llama-3.1-8B-Instruct")
    print("=" * 60)

    tester = OpenClawTester()

    # Connect
    if not await tester.connect():
        print("Failed to connect to OpenClaw. Is it running?")
        print("Start with: ~/tt-claw/bin/services")
        return 1

    # Run tests
    try:
        await tester.run_all_tests()
    except KeyboardInterrupt:
        print("\n\nTests interrupted by user")
    except Exception as e:
        print(f"\n\nTests failed with error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await tester.close()

    # Generate report
    report = tester.generate_report()

    # Save report
    report_file = f"/home/ttuser/tt-claw/openclaw-performance-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.txt"
    with open(report_file, 'w') as f:
        f.write(report)

    print(f"\n{'='*80}")
    print(f"Report saved to: {report_file}")
    print(f"{'='*80}")

    # Print report
    print("\n" + report)

    return 0

if __name__ == "__main__":
    exit(asyncio.run(main()))
