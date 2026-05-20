import os
import re

def check_mql5_file(filepath):
    print(f"Checking {filepath}...")
    with open(filepath, 'r') as f:
        content = f.read()

    # Check for basic MQL5 components
    if ".mqh" in filepath:
        if "class" not in content and "struct" not in content:
            print(f"  Warning: No class or struct found in {filepath}")

    if ".mq5" in filepath:
        if "OnInit" not in content:
            print(f"  Error: OnInit missing in {filepath}")
        if "OnTick" not in content:
            print(f"  Error: OnTick missing in {filepath}")

    # Check includes
    includes = re.findall(r'#include\s*[<"](.*?)[>"]', content)
    for inc in includes:
        if "Trade\\" in inc: continue # System include
        inc_path = inc.replace("\\", "/")
        # Try relative or absolute in MQL5/Include
        possible_paths = [
            os.path.join(os.path.dirname(filepath), inc_path),
            os.path.join("MQL5/Include", inc_path)
        ]
        found = False
        for p in possible_paths:
            if os.path.exists(p):
                found = True
                break
        if not found:
            print(f"  Error: Included file {inc} not found")

    # Check for some common MQL5 functions used
    functions = ["CopyRates", "CopyHigh", "CopyLow", "SymbolInfoDouble", "AccountInfoDouble"]
    for func in functions:
        if func in content:
            # print(f"  Found usage of {func}")
            pass

def main():
    files_to_check = [
        "MQL5/Include/CRT_SMC/MarketStructure.mqh",
        "MQL5/Include/CRT_SMC/CRTEngine.mqh",
        "MQL5/Include/CRT_SMC/SMCEngine.mqh",
        "MQL5/Include/CRT_SMC/RiskManager.mqh",
        "MQL5/Include/CRT_SMC/Confluence.mqh",
        "MQL5/Include/CRT_SMC/Execution.mqh",
        "MQL5/Include/CRT_SMC/Logger.mqh",
        "MQL5/Experts/CRT_SMC/EA_EURUSD_CRT_SMC.mq5"
    ]
    for f in files_to_check:
        if os.path.exists(f):
            check_mql5_file(f)
        else:
            print(f"Error: File {f} does not exist")

if __name__ == "__main__":
    main()
