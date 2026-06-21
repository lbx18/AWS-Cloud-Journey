# ☁️ AWS Cloud Journey — Week 1, Day 5: AWS CLI Setup & Named Profiles

> **Roadmap:** AWS Cloud Networking → Cloud Network Security  
> **Phase:** 1 — Foundation  
> **Background:** Linux · CCNA Networking  
> **Date Completed:** May 2026

---

## 📋 Table of Contents

- [Overview](#overview)
- [Task 1 — Install AWS CLI on Linux](#task-1--install-aws-cli-on-linux)
- [Task 2 — Run aws configure with Named Profile](#task-2--run-aws-configure-with-named-profile)
- [Task 3 — Test aws s3 ls and aws iam list-users](#task-3--test-aws-s3-ls-and-aws-iam-list-users)
- [Task 4 — Explore aws help Command](#task-4--explore-aws-help-command)
- [CCNA Bridge](#ccna-bridge)
- [Key Takeaways](#key-takeaways)
- [Whats Next](#whats-next)

---

## Overview

This is **Day 5 of Week 1** of my AWS Cloud Networking roadmap. Today's focus was setting up the AWS CLI on my Linux machine, authenticating with named profiles, and running real commands against my AWS account from the terminal. After four days of working in the console, today everything moves to the command line — which is where most real cloud work actually happens.

This felt very natural coming from a Linux and CCNA background. The CLI is just SSH into your infrastructure.

| Item | Detail |
|---|---|
| **Week** | Week 1 |
| **Day** | Friday |
| **Focus** | AWS CLI installation, configuration, named profiles |
| **Time Invested** | ~1.5 hours |
| **OS** | Ubuntu 26.04 LTS|
| **AWS Free Tier** | Active |
| **Status** | All tasks completed |

---

## Task 1 — Install AWS CLI on Linux

### What I did
Installed the AWS CLI v2 on Ubuntu 26.04 using the official installation method from AWS. The CLI v2 is the current version and the one used in all AWS documentation.

### Why this matters
The AWS Management Console is good for exploration and learning. But in real environments — automation, scripting, CI/CD pipelines, and security tooling — everything runs through the CLI or SDKs. Every command you run in the console has a CLI equivalent. Knowing the CLI makes you significantly faster and opens the door to infrastructure automation.

### Installation steps

```bash
# Install the awscli from ubuntu package manager
sudo apt install awscli

# Verify installation
aws --version
# Expected output: aws-cli/2.x.x Python/3.x.x Linux/x86_64
```

### Verify it works

```bash
aws --version
```

Output:
```
aws-cli/2.27.6 Python/3.12.9 Linux/6.8.0-60-generic exe/x86_64.ubuntu.24
```

### Screenshot

![AWS CLI Version](screenshots/01_aws_cli_version.png)
*aws --version output confirming CLI v2 installed on Ubuntu 26.04*

---

## Task 2 — Run aws configure with Named Profile

### What I did
Configured the AWS CLI with a **named profile** instead of the default profile. Named profiles let you manage multiple AWS accounts or multiple IAM users from the same machine — switching between them with a single flag.

### Why named profiles matter

If you use `aws configure` without a profile name, everything goes into the `default` profile. That's fine for one account. But as soon as you have:
- A personal lab account
- A work account
- A production account
- Different IAM users for different tasks

You need named profiles to keep credentials separated and avoid accidentally running commands against the wrong account.

### The credentials you need

Before running `aws configure`, you need an **Access Key ID** and **Secret Access Key** for your IAM user. These were generated on Tuesday when `lab-admin` was created.

> **Security note:** Access keys are long-term credentials. Store them only in `~/.aws/credentials` — never in code, never in environment variables permanently, never in a `.env` file pushed to GitHub.

### Configuration steps

```bash
# Configure a named profile called 'lab'
aws configure --profile lab
```

You will be prompted for four values:

```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

### What gets created

AWS CLI stores credentials and config in two separate files:

```bash
cat ~/.aws/credentials
```
```ini
[lab]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

```bash
cat ~/.aws/config
```
```ini
[profile lab]
region = us-east-1
output = json
```

### Multiple profiles on one machine

```bash
# Configure a second profile for a read-only user
aws configure --profile readonly

# List all configured profiles
aws configure list-profiles
```

Output:
```
lab
readonly
```

### Switch between profiles

```bash
# Use the lab profile
aws s3 ls --profile lab

# Use the readonly profile
aws s3 ls --profile readonly

# Or set it as default for the session
export AWS_PROFILE=lab
aws s3 ls  # now uses 'lab' profile automatically
```

### Screenshot

![AWS Configure Profile](screenshots/02_aws_configure.png)
*aws configure --profile lab — entering credentials and region*

![AWS Credentials File](screenshots/022_credentials_file.png)
*~/.aws/credentials file showing named profile stored correctly*

---

## Task 3 — Test aws s3 ls and aws iam list-users

### What I did
Ran real AWS CLI commands against my account to verify the profile is working and the IAM user has the correct permissions. Tested both S3 and IAM commands to confirm access across services.

### S3 commands

```bash
# List all S3 buckets in the account
aws s3 ls --profile lab
```

Output:
```
2026-05-20 14:32:11 my-lab-bucket
```

```bash
# List objects inside a specific bucket
aws s3 ls s3://my-lab-bucket --profile lab
```

```bash
# Get bucket location
aws s3api get-bucket-location \
  --bucket my-lab-bucket \
  --profile lab
```

Output:
```json
{
    "LocationConstraint": null
}
```
`null` means the bucket is in `us-east-1` — the default region.

### IAM commands

```bash
# List all IAM users in the account
aws iam list-users --profile lab
```

Output:
```json
{
    "Users": [
        {
            "UserName": "lab-admin",
            "UserId": "AIDAIOSFODNN7EXAMPLE",
            "Arn": "arn:aws:iam::695331051020:user/lab-admin",
            "Path": "/",
            "CreateDate": "2026-05-20T14:00:00+00:00"
        },
        {
            "UserName": "lab-readonly",
            "UserId": "AIDAIOSFODNN7EXAMPLE2",
            "Arn": "arn:aws:iam::695331051020:user/lab-readonly",
            "Path": "/",
            "CreateDate": "2026-05-21T10:30:00+00:00"
        }
    ]
}
```

```bash
# Check which identity the CLI is using right now
aws sts get-caller-identity --profile lab
```

Output:
```json
{
    "UserId": "AIDAIOSFODNN7EXAMPLE",
    "Account": "695331051020",
    "Arn": "arn:aws:iam::695331051020:user/lab-admin"
}
```

> `aws sts get-caller-identity` is the CLI equivalent of "who am I logged in as?" — use this any time you are unsure which account or user the CLI is authenticated as. I will use this constantly going forward.

### Filter output with --query

The CLI returns full JSON by default. You can filter it:

```bash
# Get only usernames — cleaner output
aws iam list-users \
  --query 'Users[*].UserName' \
  --output table \
  --profile lab
```

Output:
```
---------------------
|     ListUsers     |
+-------------------+
|  lab-admin        |
|  lab-readonly     |
+-------------------+
```

### Screenshots


![aws s3 ls output](screenshots/03_s3_ls.png)
*aws s3 ls --profile lab — listing buckets from the terminal*

![aws iam list-users output](screenshots/033_iam_list_users.png)
*aws iam list-users showing lab-admin and lab-readonly users*

![aws sts get-caller-identity](screenshots/0333_caller_identity.png)
*aws sts get-caller-identity — confirming which user the CLI is authenticated as*

---

## Task 4 — Explore aws help Command

### What I did
Spent time exploring the built-in `aws help` system to understand how to find any command without leaving the terminal. The AWS CLI has comprehensive built-in documentation — you rarely need to open a browser for syntax.

### How the help system works

```bash
# Top-level help — lists all services
aws help

# Service-level help — lists all commands for a service
aws s3 help
aws iam help
aws ec2 help

# Command-level help — full syntax for one command
aws iam create-user help
aws s3 cp help
aws ec2 describe-instances help
```

Press `q` to exit the help pager. Use `/` to search within it — same as `man` pages on Linux.

### Useful commands I discovered

```bash
# EC2 — describe all instances with filtered output
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --profile lab

# IAM — list all attached policies on a user
aws iam list-attached-user-policies \
  --user-name lab-admin \
  --profile lab

# IAM — list all groups a user belongs to
aws iam list-groups-for-user \
  --user-name lab-admin \
  --profile lab

# S3 — sync a local folder to S3
aws s3 sync ./local-folder s3://my-lab-bucket/ \
  --profile lab

# STS — check current identity (use this constantly)
aws sts get-caller-identity --profile lab
```

### Output formats

The CLI supports four output formats:

```bash
# JSON (default) — machine readable
aws iam list-users --output json --profile lab

# Table — human readable
aws iam list-users --output table --profile lab

# Text — for piping into grep/awk
aws iam list-users --output text --profile lab

# YAML — clean structured output
aws iam list-users --output yaml --profile lab
```

For daily work I use `table` when reading results and `json` when piping output into scripts.

### Screenshots

![aws help output](screenshots/04_aws_help.png)
*aws help — top-level service list in the terminal*

![aws iam help](screenshots/044_iam_help.png)
*aws iam help — all IAM subcommands listed*

---

## CCNA Bridge

The AWS CLI is the cloud equivalent of the Cisco IOS command line — instead of SSHing into a router and typing `show` commands, you type `aws` commands from your Linux machine and get the same information about your cloud infrastructure.

| Cisco IOS (2911) | AWS CLI Equivalent |
|---|---|
| `ssh admin@192.168.1.1` (connect to device) | `aws configure --profile lab` (authenticate to AWS) |
| `show ip interface brief` | `aws ec2 describe-instances --output table` |
| `show vlan brief` | `aws ec2 describe-subnets --output table` |
| `show ip route` | `aws ec2 describe-route-tables` |
| `show running-config` | `aws iam get-account-summary` |
| `show ip access-lists` | `aws iam list-attached-user-policies` |
| `show users` | `aws iam list-users` |
| `show privilege` | `aws sts get-caller-identity` |
| `terminal length 0` (disable paging) | `--output text \| cat` (disable paging) |
| Multiple enable passwords per device | Named profiles per AWS account |

**Key difference:** On a Cisco router you SSH into the device and run commands locally. With the AWS CLI you run commands from your Linux machine and AWS executes them via API — the result is the same but you never need to be "inside" the cloud.

---

## Key Takeaways

```
AWS CLI v2 installed on Ubuntu 26.04 LTS — aws --version confirms it
Named profiles keep multiple accounts and users separated cleanly
aws configure --profile lab stores credentials in ~/.aws/credentials
aws sts get-caller-identity confirms which user the CLI is authenticated as
--query filters JSON output — essential for readable results
--output table makes results human-readable in the terminal
aws help / aws <service> help / aws <service> <command> help — three levels of docs
The CLI is faster than the console for everything once you know the commands
```

### One command to always remember
```bash
aws sts get-caller-identity --profile lab
```
Run this any time you are unsure which account or identity the CLI is using. It returns your Account ID, User ARN, and User ID — three seconds to confirm you are in the right place before running any destructive command.

---

## Whats Next

| Day | Focus |
|---|---|
| **Saturday** | Full IAM lab rebuild from scratch — no guide, CLI only |
| **Sunday** | Review + AWS Well-Architected Security Framework reading |

---

## Resources Used

- [AWS CLI v2 Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS CLI Named Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
- [AWS CLI Command Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [--query JMESPath Filter Reference](https://jmespath.org/)

---

## Screenshots Folder Structure

```
Week1-friday/
├── screenshorts/
│   ├── 01_aws_cli_version.png
│   ├── 02_aws_configure.png
│   ├── 022_credentials_file.png
│   ├── 03_s3_ls.png
│   ├── 033_iam_list_users.png
│   ├── 0333_caller_identity.png
│   ├── 04_aws_help.png
│   └── 044_iam_help.png
└── week1_friday_aws_cli.md
```

> **Tip:** For Friday's screenshots, terminal captures work best with a dark terminal theme — the output is cleaner and more readable on GitHub. 

---

*Part of my AWS Cloud Networking roadmap — from Linux & CCNA background to Cloud Network Security Engineer.*  
*Follow along as I document each week of labs and learning.*
