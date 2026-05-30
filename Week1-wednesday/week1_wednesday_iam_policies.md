# ☁️ AWS Cloud Journey — Week 1, Day 3: IAM Policies & Policy Simulator

> **Roadmap:** AWS Cloud Networking → Cloud Network Security  
> **Phase:** 1 — Foundation  
> **Background:** Linux · CCNA Networking  
> **Date Completed:** May 2026

---

## 📋 Table of Contents

- [Overview](#overview)
- [Task 1 — Read IAM Policy JSON Structure](#task-1--read-iam-policy-json-structure)
- [Task 2 — Write a Custom S3 Read-Only Policy](#task-2--write-a-custom-s3-read-only-policy)
- [Task 3 — Test with IAM Policy Simulator](#task-3--test-with-iam-policy-simulator)
- [Task 4 — Attach Policy to a User](#task-4--attach-policy-to-a-user)
- [CCNA Bridge](#ccna-bridge)
- [Key Takeaways](#key-takeaways)
- [Whats Next](#whats-next)

---

## Overview

This is **Day 3 of Week 1** of my AWS Cloud Networking roadmap. Today's focus was understanding how IAM policies are structured in JSON, writing a custom policy from scratch, testing it with the IAM Policy Simulator before deploying it, and attaching it to a user. This is the most technical IAM task so far — and the most important one for security.

| Item | Detail |
|---|---|
| **Week** | Week 1 |
| **Day** | Wednesday |
| **Focus** | IAM Policy JSON Structure + Custom Policy + Simulator |
| **Time Invested** | ~2.5 hours |
| **AWS Free Tier** | Active |
| **Status** | All tasks completed |

---

## Task 1 — Read IAM Policy JSON Structure

### What I did
Studied the IAM policy JSON structure by reading the [AWS IAM policy reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html) and inspecting the built-in `AdministratorAccess` and `ReadOnlyAccess` managed policies directly in the console.

### Policy anatomy

Every IAM policy is a JSON document with the following structure:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "StatementID",
      "Effect": "Allow",
      "Action": ["service:Action"],
      "Resource": "*",
      "Condition": {}
    }
  ]
}
```

| Field | Description | CCNA Equivalent |
|---|---|---|
| `Version` | Policy language version — always `2012-10-17` | N/A — IOS has no versioning |
| `Statement` | Array of permission rules | Each `access-list` entry |
| `Effect` | `Allow` or `Deny` | `permit` or `deny` in ACL |
| `Action` | What API actions are allowed or denied | Port/protocol in extended ACL |
| `Resource` | Which AWS resources the rule applies to | Source/destination IP in ACL |
| `Condition` | Optional — restrict by IP, MFA, time, etc. | `access-class` restrictions on VTY |

### Key rules I noted
- **Explicit Deny always wins** — same as IOS ACL where a `deny` overrides any `permit`
- **Implicit Deny** — if nothing is allowed, everything is denied by default — identical to IOS ACL implicit deny at the end
- **Least privilege** — only grant what is needed, nothing more

### Screenshot


![IAM Policy Structure](/Week1-wednesday/screenshots/01_policy_structure.png)
*Inspecting AdministratorAccess managed policy JSON in the console*

---

## Task 2 — Write a Custom S3 Read-Only Policy

### What I did
Wrote a custom IAM policy from scratch that allows a user to **list and read** objects from a specific S3 bucket — but cannot write, delete, or access any other bucket.

### The policy I wrote

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ListBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::my-lab-bucket"
    },
    {
      "Sid": "AllowS3ReadObjects",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::my-lab-bucket/*"
    }
  ]
}
```

### Why two separate resource ARNs?

- `arn:aws:s3:::my-lab-bucket` — targets the **bucket itself** (for ListBucket)
- `arn:aws:s3:::my-lab-bucket/*` — targets the **objects inside** the bucket (for GetObject)

This tripped me up at first — in S3 you always need both resource lines for list + read access to work correctly.

### Steps taken
1. Go to **IAM → Policies → Create Policy**
2. Choose **JSON** tab
3. Paste the policy above
4. Policy name: `S3-ReadOnly-MyLabBucket`
5. Description: `Allows read-only access to my-lab-bucket only`
6. Create policy

### CLI equivalent
```bash
# Save the policy JSON to a file first
cat > s3-readonly-policy.json << 'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket","s3:GetBucketLocation"],
      "Resource": "arn:aws:s3:::my-lab-bucket"
    },
    {
      "Sid": "AllowS3ReadObjects",
      "Effect": "Allow",
      "Action": ["s3:GetObject","s3:GetObjectVersion"],
      "Resource": "arn:aws:s3:::my-lab-bucket/*"
    }
  ]
}
POLICY

# Create the policy in AWS
aws iam create-policy \
  --policy-name S3-ReadOnly-MyLabBucket \
  --policy-document file://s3-readonly-policy.json

# Verify
aws iam get-policy --policy-arn arn:aws:iam::ACCOUNT_ID:policy/S3-ReadOnly-MyLabBucket
```
### Screenshots

![Create Policy JSON Tab](/Week1-wednesday/screenshots/02_create_policy_json.png)
*Custom S3 read-only policy written in the JSON editor*

![Create Policy JSON Tab](/Week1-wednesday/screenshots/022_policy_created.png)
*S3-ReadOnly-MyLabBucket policy successfully created*

---

## Task 3 — Test with IAM Policy Simulator

### What I did
Before attaching the policy to any user, I used the **IAM Policy Simulator** at [policysim.aws.amazon.com](https://policysim.aws.amazon.com) to verify it behaves exactly as intended — testing both allowed and denied actions.

### Why this matters
The policy simulator lets you test what a policy will allow or deny **before** deploying it. This prevents security mistakes — you never want to discover a misconfiguration after attaching it to a real user.

> This is equivalent to using `show ip access-lists` to check your ACL hit counts before applying it to a live interface — test first, deploy second.

### Tests I ran

| Action Tested | Resource | Expected | Result |
|---|---|---|---|
| `s3:ListBucket` | `my-lab-bucket` | Allow | ✅ Allowed |
| `s3:GetObject` | `my-lab-bucket/*` | Allow | ✅ Allowed |
| `s3:PutObject` | `my-lab-bucket/*` | Deny | ✅ Denied |
| `s3:DeleteObject` | `my-lab-bucket/*` | Deny | ✅ Denied |
| `s3:ListBucket` | `other-bucket` | Deny | ✅ Denied |
| `s3:GetObject` | `other-bucket/*` | Deny | ✅ Denied |
| `ec2:DescribeInstances` | `*` | Deny | ✅ Denied |

All 7 tests passed as expected — the policy is scoped correctly.

### Steps taken
1. Go to [policysim.aws.amazon.com](https://policysim.aws.amazon.com)
2. Select **IAM Policies** → choose `S3-ReadOnly-MyLabBucket`
3. Select **Amazon S3** as the service
4. Run each action above with the appropriate resource ARN
5. Verify Allow/Deny results match expectations

### Screenshots

![Policy Simulator](/Week1-wednesday/screenshots/03_policy_simulator.png)
*IAM Policy Simulator — testing s3:GetObject — result: Allowed*

![Policy Simulator Deny](/Week1-wednesday/screenshots/033_policy_simulator_deny.png)
*IAM Policy Simulator — testing s3:PutObject — result: Denied*

---

## Task 4 — Attach Policy to a User

### What I did
Created a new read-only IAM user named `lab-readonly` and attached the custom `S3-ReadOnly-MyLabBucket` policy to it. Then logged in as that user and verified the restrictions actually work in practice.

### Steps taken
1. Go to **IAM → Users → Create User**
2. Username: `lab-readonly`
3. Enable console access
4. Go to **Permissions → Add permissions → Attach policies directly**
5. Search for and attach `S3-ReadOnly-MyLabBucket`
6. Log in as `lab-readonly` in a different browser
7. Attempt to list objects in `my-lab-bucket` — success
8. Attempt to upload an object — access denied
9. Attempt to open EC2 console — access denied

### Verification test

```bash
# Configure a new CLI profile for lab-readonly user
aws configure --profile readonly

# Test: list objects — should WORK
aws s3 ls s3://my-lab-bucket --profile readonly

# Test: upload a file — should FAIL
aws s3 cp test.txt s3://my-lab-bucket/ --profile readonly
# Expected: An error occurred (AccessDenied)

# Test: describe EC2 instances — should FAIL
aws ec2 describe-instances --profile readonly
# Expected: An error occurred (UnauthorizedOperation)
```

### CLI equivalent
```bash
# Attach policy to user
aws iam attach-user-policy \
  --user-name lab-readonly \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/S3-ReadOnly-MyLabBucket

# Verify
aws iam list-attached-user-policies --user-name lab-readonly
```

### Screenshots


![Policy Attached to User](/Week1-wednesday/screenshots/04_policy_attached.png)
*S3-ReadOnly-MyLabBucket policy attached to lab-readonly user*

![Access Denied Upload](/Week1-wednesday/screenshots/044_access_denied.png)
*lab-readonly user gets AccessDenied when attempting to upload — policy working correctly*

![EC2 Access Denied](/Week1-wednesday/screenshots/0444_ec2_denied.png)
*EC2 console blocked for lab-readonly — scoped to S3 only*

---

## CCNA Bridge

Today's work maps directly to Extended Named ACLs on the Cisco 2911:

| Cisco IOS (2911) | AWS IAM Policy Equivalent |
|---|---|
| `ip access-list extended S3_READONLY` | `aws iam create-policy --policy-name S3-ReadOnly-MyLabBucket` |
| `permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.10 eq 80` | `"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::my-lab-bucket/*"` |
| `deny tcp any any eq 21` | `"Effect":"Deny","Action":"s3:PutObject","Resource":"*"` |
| `deny ip any any` (implicit) | IAM implicit deny — if not explicitly allowed, it is denied |
| `show ip access-lists` (check before applying) | IAM Policy Simulator (test before attaching) |
| `ip access-group S3_READONLY in` (apply to interface) | `aws iam attach-user-policy` (attach to user) |
| `show access-lists` hit counts | CloudTrail API call logs (who did what) |

**Key insight:** Writing an IAM policy feels identical to writing an extended ACL — you define what is permitted, what is denied, and apply it to a principal. The JSON format is more verbose, but the logic is exactly the same.

---

## Key Takeaways

```
Understood IAM policy JSON anatomy: Version, Statement, Effect, Action, Resource
Wrote a custom S3 read-only policy scoped to a single bucket
Used the IAM Policy Simulator to verify allow/deny behaviour before deploying
Attached policy to lab-readonly user and confirmed restrictions work in practice
Explicit Deny wins over Allow — same as IOS ACL behaviour
Two resource ARNs needed for S3: one for the bucket, one for the objects inside
```

### One thing that tripped me up
The S3 `ListBucket` action must target the **bucket ARN** (`arn:aws:s3:::my-lab-bucket`) while `GetObject` must target the **object ARN** (`arn:aws:s3:::my-lab-bucket/*`). Using `*` for both causes the `ListBucket` action to silently fail. This took me a few minutes to debug.

### One thing that was different from CCNA
In Cisco IOS ACLs there is no built-in simulator — you apply the ACL and test with ping or traffic. In AWS you can fully simulate every permission before touching a real user. This is a major improvement for security engineering.

---

## Whats Next

| Day | Focus |
|---|---|
| **Thursday** | IAM roles — when to use roles vs users, attaching roles to EC2 |
| **Friday** | AWS CLI setup on Linux + authenticating with named profiles |
| **Saturday** | Full IAM lab rebuild from scratch (no guide) |
| **Sunday** | Review + AWS Well-Architected Security reading |

---

## Resources Used

- [AWS IAM Policy Reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html)
- [IAM Policy Simulator](https://policysim.aws.amazon.com/)
- [S3 Actions Reference](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html)
- [AWS Policy Examples](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_examples.html)

---

## Screenshots Folder Structure

```
Week1-wednesday/
├── screenshorts/
│   ├── 01_policy_structure.png
│   ├── 02_create_policy_json.png
│   ├── 022_policy_created.png
│   ├── 03_policy_simulator.png
│   ├── 033_policy_simulator_deny.png
│   ├── 04_policy_attached.png
│   ├── 044_access_denied.png
│   └── 0444_ec2_denied.png
└── week1_wednesday_iam_policies.md
```

> **Tip:** Keep the same naming pattern as Monday and Tuesday — GitHub will render all images inline automatically when paths are relative.

---

*Part of my AWS Cloud Networking roadmap — from Linux & CCNA background to Cloud Network Security Engineer.*  
*Follow along as I document each week of labs and learning.*
