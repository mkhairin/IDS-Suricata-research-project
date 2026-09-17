# 🛡️ Suricata IDS Rule Tuning Research Project

> **Optimizing Suricata IDS Detection Rules to Improve Cyber Attack Detection Accuracy**

This repository contains research artifacts, custom detection rules, evaluation results, and documentation from an experimental study focused on improving the detection capability of **Suricata Intrusion Detection System (IDS)** through systematic **rule tuning and custom rule development**.

The research investigates detection blind spots in the default Suricata ruleset and evaluates whether customized detection rules can improve detection performance across multiple network and web-based attack scenarios.

---

## 📌 Research Overview

Signature-based Intrusion Detection Systems depend heavily on the quality and coverage of their detection rules. Although Suricata provides extensive detection capabilities, default rules may not always detect attack patterns generated under specific environments or traffic characteristics.

This research evaluates those limitations using controlled attack simulations and develops **28 custom Suricata rules** using several detection approaches:

- Behavioral detection
- Threshold-based detection
- Layer-7 payload inspection
- Flow and TCP flag analysis
- PCRE-based pattern matching
- Multi-stage detection

The effectiveness of the tuning process was evaluated by comparing detection performance before and after rule implementation.

---

## 🎯 Research Objectives

The main objectives of this research are:

1. Identify detection blind spots in the default Suricata IDS rules.
2. Analyze attack patterns that are not consistently detected.
3. Develop custom detection rules based on network and application-layer behavior.
4. Evaluate the effectiveness of rule tuning using controlled attack simulations.
5. Measure improvements using confusion-matrix-based metrics.
6. Evaluate the generalization capability of selected rules against attack variations.

---

## 🧪 Experimental Environment

The experiment was conducted in an isolated virtualized cybersecurity laboratory.

| Component | Configuration |
|---|---|
| IDS Engine | Suricata 8.0.2 |
| Operating System | Ubuntu Server 22.04 LTS |
| Deployment Mode | IDS / Passive Detection |
| Test Design | Interleaved Experimental Design |
| Test Sets | Set A, Set B, Set C |
| Total Test Rounds | 30 |

### Laboratory Topology

```text
┌──────────────────────┐
│    Attacker Machine  │
│      Kali Linux      │
└──────────┬───────────┘
           │
           │ Attack Traffic
           ▼
┌──────────────────────┐
│     Suricata IDS     │
│ Ubuntu Server 22.04  │
│    Suricata 8.0.2    │
└──────────┬───────────┘
           │
           │ Monitored Traffic
           ▼
┌──────────────────────┐
│    Victim Machine    │
│ Metasploitable/DVWA  │
└──────────────────────┘
```

---

## ⚔️ Attack Scenarios

Seven attack categories were used to evaluate Suricata detection capability.

| # | Attack Scenario | Tool / Technique | Detection Focus |
|---|---|---|---|
| 1 | Port Scanning | Nmap | Network reconnaissance |
| 2 | SSH Brute Force | Hydra | Authentication attack |
| 3 | Denial of Service | hping3 | Traffic flooding |
| 4 | SQL Injection | sqlmap | Web application attack |
| 5 | Cross-Site Scripting | curl / crafted payload | Web application attack |
| 6 | Path Traversal | curl | File access attack |
| 7 | Remote Code Execution | Metasploit | Exploitation |

---

## 📊 Dataset

The primary evaluation consisted of:

```text
Total Samples     : 1,050
Attack Samples    :   630
Normal Samples    :   420
```

The normal traffic dataset included seven controlled categories of legitimate activity:

- File download using `wget`
- `apt update`
- Successful SSH login
- Large ICMP packets
- FTP login
- Non-standard HTTP requests
- HTTP 404 requests

> **Note:** The normal traffic dataset represents controlled laboratory scenarios and should not be interpreted as representative of all real-world benign network traffic.

---

## 🔎 Pre-Test — Default Rules

The first stage evaluated Suricata using the existing/default detection rules.

### Confusion Matrix

| Metric | Result |
|---|---:|
| True Positive (TP) | 147 |
| False Negative (FN) | 483 |
| False Positive (FP) | 0 |
| True Negative (TN) | 420 |
| **Total Samples** | **1,050** |

### Detection Performance

| Metric | Result |
|---|---:|
| Recall | **23.33%** |
| Accuracy | **54.00%** |
| Precision | **100%** |

The baseline evaluation revealed substantial detection blind spots.

Particularly significant blind spots were observed in application-layer attacks:

```text
SQL Injection          → 0% detection
Cross-Site Scripting   → 0% detection
```

Other attacks, including SSH brute force, path traversal, and remote code execution, showed inconsistent detection.

Port scanning and denial-of-service attacks were comparatively more detectable by the existing rules.

---

## 🛠️ Rule Tuning

Based on the blind spots identified during the Pre-Test, **28 custom detection rules** were developed.

### Custom Rule Distribution

| Attack Category | Custom Rules |
|---|---:|
| Port Scanning | 6 |
| SSH Brute Force | 3 |
| Denial of Service | 4 |
| SQL Injection | 4 |
| Cross-Site Scripting | 4 |
| Path Traversal | 3 |
| Remote Code Execution | 4 |
| **Total** | **28** |

---

## 🧠 Detection Engineering Approaches

Different attack categories required different detection strategies.

### 1. Behavioral Detection

Behavioral patterns were used where a single packet was insufficient to classify malicious activity.

```text
Multiple Connection Attempts
            │
            ▼
       Same Source
            │
            ▼
    Short Time Interval
            │
            ▼
    Threshold Exceeded
            │
            ▼
      Generate Alert
```

This approach was particularly useful for:

- Port scanning
- SSH brute force
- Denial-of-Service attacks

---

### 2. Threshold-Based Detection

Threshold mechanisms were used to identify abnormal request frequency.

Example:

```suricata
threshold:type both, track by_src, count 4, seconds 120;
```

Threshold values were determined based on attack behavior observed during controlled experiments and tuned to distinguish simulated malicious activity from the normal traffic scenarios used in the study.

---

### 3. TCP Flag Analysis

TCP flags were analyzed to identify reconnaissance techniques such as:

- SYN Scan
- FIN Scan
- NULL Scan
- XMAS Scan

Example detection logic:

```suricata
flags:S,12;
flow:not_established;
```

Stateless detection was also used for stealth scanning techniques where appropriate.

---

### 4. Layer-7 Payload Inspection

Application-layer attacks required inspection of HTTP components such as:

```text
http.uri
http.header
http.request_body
```

This approach was primarily used for:

- SQL Injection
- Cross-Site Scripting
- Path Traversal

---

### 5. PCRE Pattern Matching

PCRE was used to detect payload variations that could not be reliably identified using simple static content matching.

SQL Injection detection included patterns involving:

```text
UNION
SELECT
SQL comments
Keyword variations
```

XSS detection focused on patterns such as:

```text
<script>
onload=
onerror=
alert()
```

---

### 6. Multi-Stage Detection

Remote Code Execution scenarios were analyzed using multiple observable stages rather than relying exclusively on a single payload signature.

```text
Reconnaissance
      │
      ▼
Exploit Trigger
      │
      ▼
Payload / Command
      │
      ▼
Post-Exploitation Traffic
      │
      ▼
Suricata Alert
```

---

## 🚀 Post-Test Results

After implementing the custom detection rules, the experiment was repeated using the same primary evaluation framework.

### Confusion Matrix

| Metric | Result |
|---|---:|
| True Positive (TP) | 628 |
| False Negative (FN) | 2 |
| True Negative (TN) | 420 |
| Attack Samples | 630 |
| Normal Samples | 420 |

### Detection Performance

| Metric | Pre-Test | Post-Test |
|---|---:|---:|
| Recall | 23.33% | **99.68%** |
| Accuracy | 54.00% | **99.81%** |

The results demonstrate a substantial improvement in attack detection after rule tuning.

```text
PRE-TEST                       POST-TEST
──────────────────────────────────────────────

Detected : 147 / 630           Detected : 628 / 630
Missed   : 483 / 630           Missed   :   2 / 630

Recall   : 23.33%              Recall   : 99.68%
Accuracy : 54.00%              Accuracy : 99.81%
```

---

## ⚠️ Alert Overlap Analysis

During Post-Test analysis, **40 cross-category alert overlaps** were observed.

These events should be distinguished from false positives generated by benign traffic.

| Original Scenario | Triggered Rule Category | Events |
|---|---|---:|
| Port Scanning | Hydra / SSH Detection | 30 |
| DoS | Nmap Detection | 10 |
| **Total** | | **40** |

Different attacks can exhibit similar network behavior.

For example:

```text
Port Scanning
      │
      ▼
High Connection Frequency
      │
      ▼
Behavior Similar to
Brute-Force Detection
      │
      ▼
Multiple Rules Triggered
```

Although these events are not equivalent to benign-traffic false positives, overlapping alerts can still increase analyst workload and contribute to **alert fatigue** in operational environments.

Correlation, suppression, or additional rule refinement may therefore be required before production deployment.

---

## 🧬 Generalization Test

Additional testing was performed to determine whether selected custom rules could detect attack variations beyond the exact payloads used during initial rule development.

The generalization experiment focused on:

- SQL Injection
- Cross-Site Scripting

Each category was evaluated across **15 repetitions** using payload variations.

### SQL Injection Variations

SQLMap tamper techniques included:

```text
space2randomblank
unionalltounion
versionedkeywords
```

Example SQL structures observed during testing included variations involving:

```sql
UNION ALL SELECT NULL
```

and queries containing:

```sql
INFORMATION_SCHEMA
JSON_ARRAYAGG()
CONCAT()
```

The custom SQL Injection rules successfully detected the tested variations.

### Cross-Site Scripting Variations

XSS testing included variations involving script-related and event-handler patterns such as:

```html
<script>
onload=
onerror=
alert()
```

The tested variations successfully triggered the corresponding custom XSS detection rules.

---

## 🔬 False Negative Analysis

Two False Negative events remained during the Post-Test.

Both occurred in the Remote Code Execution scenario involving:

```text
exploit/unix/ftp/vsftpd_234_backdoor
```

Investigation indicated that the Metasploit module did not retransmit the expected exploitation payload during those repetitions.

As a result, the traffic pattern required to trigger the corresponding detection rule was not generated.

These cases were therefore documented as an **experimental/methodological limitation** rather than being attributed solely to rule logic.

---

## 📂 Repository Structure

```text
IDS-Suricata-research-project/
│
├── README.md
├── LICENSE
│
├── rules/
│   ├── port-scanning.rules
│   ├── ssh-bruteforce.rules
│   ├── dos.rules
│   ├── sqli.rules
│   ├── xss.rules
│   ├── path-traversal.rules
│   └── rce.rules
│
├── evaluation/
│   ├── pre-test/
│   ├── post-test/
│   ├── confusion-matrix/
│   ├── recall-analysis/
│   └── generalization-test/
│
├── datasets/
│   ├── attack-traffic/
│   └── normal-traffic/
│
├── docs/
│   ├── methodology/
│   ├── rule-analysis/
│   └── experimental-results/
│
├── images/
│   ├── architecture/
│   ├── detection-results/
│   └── charts/
│
└── paper/
    └── research-paper.pdf
```

> The actual directory structure may evolve as research artifacts are cleaned, documented, and published.

---

## 📐 Evaluation Metrics

### Recall

```text
Recall = TP / (TP + FN)
```

Recall measures the IDS capability to detect actual attacks.

### Precision

```text
Precision = TP / (TP + FP)
```

Precision measures the proportion of positive detections that are correctly classified under the evaluation scheme.

### Accuracy

```text
Accuracy = (TP + TN) / (TP + TN + FP + FN)
```

Accuracy measures overall classification performance within the experimental dataset.

---

## 🔄 Research Workflow

```text
┌──────────────────────────┐
│ Default Suricata Rules   │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│         Pre-Test         │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Identify Detection       │
│ Blind Spots              │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Analyze Attack Traffic   │
│ & Detection Behavior     │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Develop & Tune           │
│ Custom Suricata Rules    │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│        Post-Test         │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Evaluate Detection       │
│ Performance              │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Generalization Test      │
│ SQLi & XSS Variants      │
└──────────────────────────┘
```

---

## ⚠️ Research Limitations

This research was conducted in a **controlled virtual laboratory environment**.

1. The normal traffic dataset contains seven controlled traffic scenarios and does not represent the full diversity of production network traffic.
2. Attack simulations were performed using specific tools and configurations.
3. Threshold values were optimized within the characteristics of the experimental environment.
4. Detection performance may differ in high-volume or heterogeneous production networks.
5. Encrypted traffic may limit Layer-7 payload inspection without additional visibility mechanisms.
6. Cross-category alert overlap may increase alert volume in operational deployments.
7. Further validation using real-world traffic and larger benign datasets is required before production deployment.

Therefore, the reported detection performance should be interpreted as results from the experimental environment rather than universal Suricata performance.

---

## 🛡️ Responsible Use

The attack simulations, detection rules, and testing procedures in this repository were developed for:

- Cybersecurity research
- Defensive security
- Intrusion detection engineering
- Security education
- Controlled laboratory testing

> **Do not use attack techniques contained in this repository against systems without explicit authorization.**

---

## 🔮 Future Work

Potential extensions of this research include:

```text
Suricata IDS
     │
     ├──► Wazuh / SIEM Integration
     ├──► Telegram Real-Time Alerting
     ├──► Automated Rule Validation
     ├──► Detection-as-Code Pipeline
     ├──► MITRE ATT&CK Mapping
     ├──► PCAP-Based Regression Testing
     ├──► Larger Benign Traffic Dataset
     ├──► IDS → IPS Evaluation
     └──► Hybrid / Anomaly-Based Detection
```

---

## 🧑‍💻 Author

**Muhammad Khairin**

Computer and Network Engineering Technology  
Politeknik Negeri Tanah Laut

### Research Interests

- Cybersecurity
- Detection Engineering
- Intrusion Detection Systems
- SOC / SIEM
- Application Security
- Network Security

GitHub: **[@mkhairin](https://github.com/mkhairin)**

---

## 📖 Research Background

This repository is based on the final project research:

> **“Optimizing Suricata IDS Rules (Rule Tuning) to Improve Cyber Attack Detection Accuracy”**

The project investigates how systematic rule tuning can reduce detection blind spots and improve Suricata IDS detection performance within a controlled experimental environment.

---

## ⭐ Repository Purpose

This repository serves as:

- Research documentation
- Detection engineering portfolio
- Suricata custom rule collection
- Experimental evaluation archive
- Reproducible cybersecurity laboratory reference

Contributions, discussions, and suggestions regarding Suricata detection engineering and rule optimization are welcome.
