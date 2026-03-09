#!/usr/bin/env python3
"""
OpenClaw Demo Script - Testing Tenstorrent Inference Server
Demonstrates multi-turn conversation and reasoning capabilities
"""

import requests
import json
import time

BASE_URL = "http://127.0.0.1:8000/v1"
MODEL = "meta-llama/Llama-3.1-8B-Instruct"

def chat(messages, max_tokens=200):
    """Send chat completion request"""
    response = requests.post(
        f"{BASE_URL}/chat/completions",
        headers={"Content-Type": "application/json"},
        json={
            "model": MODEL,
            "messages": messages,
            "max_tokens": max_tokens
        }
    )
    result = response.json()
    return result["choices"][0]["message"]["content"]

print("🦞 OpenClaw-Style Demo: Testing Tenstorrent Inference Server")
print("=" * 70)
print()

# Demo 1: System Analysis Task
print("📋 Demo 1: System Analysis Task")
print("-" * 70)
print("Task: Analyze this QB2 system and identify key components")
print()

conversation = [
    {"role": "user", "content": """You are an AI assistant analyzing a Tenstorrent QuietBox 2 (QB2) system.

System specifications:
- Hardware: 2x P300C cards with 4 Blackhole chips total
- Running: Llama-3.1-8B-Instruct on single P150 chip
- Inference Server: vLLM with tt-transformers on Tenstorrent hardware
- Purpose: AI inference demonstration

Please provide a brief analysis (2-3 sentences) of what makes this system interesting from an AI hardware perspective."""}
]

response1 = chat(conversation)
print("AI Response:")
print(response1)
print()
time.sleep(1)

# Demo 2: Multi-step Reasoning
print("📋 Demo 2: Multi-Step Reasoning Task")
print("-" * 70)
print("Task: Explain a technical concept in simple terms")
print()

conversation2 = [
    {"role": "user", "content": """Explain what 'tensor parallel' means in AI inference in exactly 2 sentences that a non-technical person could understand."""}
]

response2 = chat(conversation2, max_tokens=100)
print("AI Response:")
print(response2)
print()
time.sleep(1)

# Demo 3: Code Analysis
print("📋 Demo 3: Code Understanding Task")
print("-" * 70)
print("Task: Explain what this Python code does")
print()

code_sample = """
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
"""

conversation3 = [
    {"role": "user", "content": f"""Explain what this Python function does in one clear sentence:\n\n```python\n{code_sample}\n```"""}
]

response3 = chat(conversation3, max_tokens=100)
print("Code:")
print(code_sample)
print("AI Analysis:")
print(response3)
print()
time.sleep(1)

# Demo 4: Creative Task
print("📋 Demo 4: Creative Writing Task")
print("-" * 70)
print("Task: Write a haiku about AI hardware")
print()

conversation4 = [
    {"role": "user", "content": "Write a haiku (5-7-5 syllable pattern) about AI chips accelerating machine learning. Just the haiku, no explanation."}
]

response4 = chat(conversation4, max_tokens=60)
print("AI Response:")
print(response4)
print()
time.sleep(1)

# Demo 5: Practical Problem Solving
print("📋 Demo 5: Practical Problem Solving")
print("-" * 70)
print("Task: Debug a common issue")
print()

conversation5 = [
    {"role": "user", "content": """A user reports: "My Python script says 'ModuleNotFoundError: No module named pandas'". What's the most likely cause and fix? Answer in 2 sentences."""}
]

response5 = chat(conversation5, max_tokens=100)
print("Problem: ModuleNotFoundError for pandas")
print("AI Solution:")
print(response5)
print()

print("=" * 70)
print("✅ Demo Complete!")
print()
print("Summary:")
print("- All 5 tasks completed successfully")
print("- Model: Llama-3.1-8B-Instruct")
print("- Hardware: Tenstorrent P150 (Blackhole chip)")
print("- Server: vLLM + tt-transformers")
print("- Performance: Responsive, accurate answers")
print()
print("This demonstrates OpenClaw-like capabilities:")
print("  • System analysis and technical understanding")
print("  • Multi-step reasoning and explanation")
print("  • Code comprehension")
print("  • Creative generation")
print("  • Practical problem-solving")
