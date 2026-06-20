# ☁️ AWS Cloud Journey — Week 1, Day 4: IAM Roles

> **Roadmap:** AWS Cloud Networking → Cloud Network Security  
> **Phase:** 1 — Foundation  
> **Background:** Linux · CCNA Networking  
> **Date Completed:** May 2026

---

## 📋 Table of Contents

- [Overview](#overview)
- [Task 1 — Create an EC2 IAM Role](#task-1--create-an-ec2-iam-role)
- [Task 2 — Attach AmazonS3ReadOnly Policy](#task-2--attach-amazons3readonly-policy)
- [Task 3 — Understand When Roles Beat Users](#task-3--understand-when-roles-beat-users)
- [Task 4 — Watch Roles vs Users vs Groups](#task-4--watch-roles-vs-users-vs-groups)
- [CCNA Bridge](#ccna-bridge)
- [Key Takeaways](#key-takeaways)
- [Whats Next](#whats-next)

---

## Overview

This is **Day 4 of Week 1** of my AWS Cloud Networking roadmap. Today's focus was IAM roles — what they are, how they differ from users and groups, and how to attach one to an EC2 instance so the instance itself can make AWS API calls without hardcoding credentials anywhere.

This was a concept shift from the previous three days. Users are for humans. Roles are for machines and services.

| Item | Detail |
|---|---|
| **Week** | Week 1 |
| **Day** | Thursday |
| **Focus** | IAM Roles — creation, attachment, use cases |
| **Time Invested** | ~2 hours |
| **AWS Free Tier** | Active |
| **Status** | All tasks completed |

---

## Task 1 — Create an EC2 IAM Role

### What I did
Created an IAM role with EC2 as the **trusted entity** — meaning only EC2 instances are allowed to assume this role. This is called a trust policy and it answers the question: who is allowed to use this role?

### What a role actually is

A role is a set of permissions with no permanent credentials attached. Unlike a user (which has a username, password, and access keys), a role is assumed temporarily — AWS generates short-lived credentials automatically when a service or user assumes it.

```
User  →  permanent credentials (access key ID + secret)
Role  →  temporary credentials (assumed on demand, auto-expire)
```

### The trust policy AWS created automatically

When you select EC2 as the trusted entity, AWS writes this trust policy behind the scenes:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

This says: **EC2 instances are allowed to assume this role**. Nothing else — not a user, not Lambda, not another service. Only EC2.

### Steps taken
1. Go to **IAM → Roles → Create Role**
2. Trusted entity type: **AWS Service**
3. Use case: **EC2**
4. Click Next — proceed to permissions

### CLI equivalent
```bash
# Create the trust policy file
cat > ec2-trust-policy.json << 'TRUST'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
TRUST

# Create the role
aws iam create-role \
  --role-name EC2-S3-ReadOnly-Role \
  --assume-role-policy-document file://ec2-trust-policy.json

# Verify
aws iam get-role --role-name EC2-S3-ReadOnly-Role
```

### Screenshot


![Create IAM Role](/Week1-thursday/screenshots/01_create_role.png)

![Create IAM Role](/Week1-thursday/screenshots/011_create_role.png)
*Creating EC2 IAM role — trusted entity set to EC2 service*

---

## Task 2 — Attach AmazonS3ReadOnly Policy

### What I did
Attached the AWS managed policy `AmazonS3ReadOnlyAccess` to the role. This gives any EC2 instance that assumes the role read-only access to all S3 buckets in the account.

### The permission policy attached

`AmazonS3ReadOnlyAccess` looks like this under the hood:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Describe*",
        "s3-object-lambda:Get*",
        "s3-object-lambda:List*"
      ],
      "Resource": "*"
    }
  ]
}
```

The wildcard `s3:Get*` matches every action that starts with Get — `GetObject`, `GetBucketPolicy`, `GetObjectTagging`, and so on.

### Steps taken
1. In the role creation wizard — **Add permissions**
2. Search for `AmazonS3ReadOnlyAccess`
3. Select it → Next
4. Role name: `EC2-S3-ReadOnly-Role`
5. Description: `Allows EC2 instances to read from S3 — no write access`
6. Create role

### Attach to an existing EC2 instance

```bash
# Attach the policy to the role
aws iam attach-role-policy \
  --role-name EC2-S3-ReadOnly-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create an instance profile (required wrapper to attach role to EC2)
aws iam create-instance-profile \
  --instance-profile-name EC2-S3-ReadOnly-Profile

aws iam add-role-to-instance-profile \
  --instance-profile-name EC2-S3-ReadOnly-Profile \
  --role-name EC2-S3-ReadOnly-Role

# Attach to a running EC2 instance
aws ec2 associate-iam-instance-profile \
  --instance-id i-XXXXXXXXXXXXXXXXX \
  --iam-instance-profile Name=EC2-S3-ReadOnly-Profile

# Verify the role is attached
aws ec2 describe-iam-instance-profile-associations
```

### Test from inside the EC2 instance

Once the role is attached, SSH into the EC2 instance and run:

```bash
# No credentials needed — the role provides them automatically
aws s3 ls

# Should list all buckets — role gives read access
aws s3 ls s3://my-lab-bucket

# Should FAIL — role is read-only
aws s3 cp test.txt s3://my-lab-bucket/
# An error occurred (AccessDenied)
```

### Screenshots


![Policy Attached to Role](/Week1-thursday/screenshots/02_policy_attached_to_role.png)
*AmazonS3ReadOnlyAccess policy attached to EC2-S3-ReadOnly-Role*

![Role Attached to EC2](/Week1-thursday/screenshots/022_role_attached_ec2.png)
*Role successfully associated with EC2 instance*

![S3 List from EC2](/Week1-thursday/screenshots/0222_s3_list_from_ec2.png)
*aws s3 ls running from inside EC2 — no credentials configured, role provides them*

---

## Task 3 — Understand When Roles Beat Users

### What I did
Compared roles vs users vs groups across real scenarios to understand when each one is the right tool.

### The core difference

```
User   →  a human logging in with a password and access keys
Group  →  a collection of users sharing the same policies
Role   →  a set of permissions assumed temporarily by a service, application, or user
```

### When to use each

| Scenario | Right choice | Why |
|---|---|---|
| Developer logging into AWS console | IAM User | Human needs permanent credentials |
| Multiple developers needing same access | IAM Group | Manage permissions in one place |
| EC2 instance needs to read from S3 | IAM Role | No hardcoded credentials on the server |
| Lambda function writing to DynamoDB | IAM Role | Serverless — no server to store keys on |
| Cross-account access | IAM Role | Users in Account A assume a role in Account B |
| CI/CD pipeline deploying to AWS | IAM Role | Short-lived credentials, no long-term key exposure |
| Auditor needs read-only access temporarily | IAM Role | Assume role for the session, credentials expire |

### Why roles are better than hardcoded credentials

A common mistake beginners make is putting AWS access keys directly in application code or on EC2 instances:

```bash
# WRONG — never do this
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Problems with hardcoded credentials:
- If the code goes to GitHub, the keys are exposed permanently
- Keys never expire unless manually rotated
- If the EC2 instance is compromised, the attacker has permanent AWS access

With an IAM role:
- No credentials stored anywhere on the instance
- Credentials are temporary — expire every 1–12 hours automatically
- If the instance is compromised, the attacker only gets short-lived credentials
- Rotation happens automatically — nothing to manage

### Screenshot


![Roles vs Users Comparison](/Week1-thursday/screenshots/03_roles_vs_users.png)
*IAM roles list — showing EC2-S3-ReadOnly-Role with trust policy*

---

## Task 4 — Watch Roles vs Users vs Groups

### What I did
Spent 10 minutes watching the AWS IAM deep dive segment on roles, users, and groups from the FreeCodeCamp AWS course to consolidate everything from the week into one mental model.

### The mental model I built

```
                    ┌─────────────────────────────────────┐
                    │           AWS ACCOUNT                │
                    │                                      │
                    │  ┌──────────┐    ┌───────────────┐  │
                    │  │  GROUP   │    │     ROLE      │  │
                    │  │          │    │               │  │
                    │  │ Policy A │    │  Trust Policy │  │
                    │  │ Policy B │    │  (who can use)│  │
                    │  └────┬─────┘    │               │  │
                    │       │          │  Perm Policy  │  │
                    │  ┌────▼─────┐    │  (what it can)│  │
                    │  │  USER    │    └───────┬───────┘  │
                    │  │          │            │           │
                    │  │ Console  │       assumed by       │
                    │  │ CLI keys │            │           │
                    │  └──────────┘    ┌───────▼───────┐  │
                    │                  │  EC2 / Lambda │  │
                    │                  │  App / Service│  │
                    │                  └───────────────┘  │
                    └─────────────────────────────────────┘
```

### Key things I noted from the video
- A role can be assumed by **multiple services simultaneously** — many EC2 instances can use the same role at the same time
- You can also allow **IAM users to assume roles** — useful for switching between dev and prod environments without separate accounts
- **AWS STS** (Security Token Service) is the underlying service that issues the temporary credentials when a role is assumed — the CLI call is `sts:AssumeRole`

### Screenshot

![IAM Summary Dashboard](screenshots/04_iam_summary.png)
*IAM dashboard showing users, groups, roles, and policies created this week*

---

## CCNA Bridge

Roles don't have a direct Cisco IOS equivalent, but the closest comparison is **RADIUS/TACACS+ authentication with privilege levels** — where a network device asks an external server for temporary authorization rather than using local credentials stored on the device itself.

| Cisco IOS (2911) | AWS IAM Role Equivalent |
|---|---|
| `username admin privilege 15` (local user on device) | IAM User (permanent credentials) |
| `aaa authentication login default group tacacs+` (delegate auth to server) | IAM Role (temporary credentials from STS) |
| `privilege exec level 5 show ip route` (what that level can do) | Role permission policy (what the role can do) |
| TACACS+ server decides who can authenticate | Trust policy decides who can assume the role |
| Session expires when you log out | Role credentials expire automatically (1–12 hrs) |
| `debug aaa authentication` | CloudTrail — logs every `sts:AssumeRole` event |

**Key insight:** Just like you would never hardcode passwords in a Cisco config file you're going to share, you never hardcode AWS credentials in code or on servers. Roles solve this the same way TACACS+ solves it on a network — authentication is delegated, temporary, and centrally managed.

---

## Key Takeaways

```
Roles are for services and applications — users are for humans
A role has two policies: trust policy (who can use it) and permission policy (what it can do)
EC2 instances get temporary credentials from the instance metadata service automatically
Never hardcode AWS credentials in code or on servers — always use roles
Credentials from a role auto-expire — much safer than long-lived access keys
Multiple EC2 instances can assume the same role simultaneously
sts:AssumeRole is the underlying API call — AWS STS issues the temp credentials
```

---

## Whats Next

| Day | Focus |
|---|---|
| **Friday** | AWS CLI setup on Linux + authenticating with named profiles |
| **Saturday** | Full IAM lab rebuild from scratch (no guide) |
| **Sunday** | Review + AWS Well-Architected Security reading |

---

## Resources Used

- [AWS IAM Roles Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [AWS STS Documentation](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)
- [Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)
- [FreeCodeCamp AWS Course](https://www.youtube.com/watch?v=3hLmDS179YE)

---

## Screenshots Folder Structure

```
Week1-thursday/
├── screenshorts/
│   ├── 01_create_role.png
│   ├── 02_policy_attached_to_role.png
│   ├── 022_role_attached_ec2.png
│   ├── 0222_s3_list_from_ec2.png
│   ├── 03_roles_vs_users.png
│   └── 04_iam_summary.png
└── week1_thursday_iam_roles.md
```


---

*Part of my AWS Cloud Networking roadmap — from Linux & CCNA background to Cloud Network Security Engineer.*  
*Follow along as I document each week of labs and learning.*

## Session Summary — The Four Pillars of IAM

![AWS IAM Essentials](/Week1-thursday/screenshots/Identity_and_Access_Management_Essentials.png)

Today's session covered all four pillars shown in the diagram above:

**Pillar 1 — IAM Users and Groups:** Users represent individual identities with long-term credentials (password + access keys). Groups allow bulk permission management through inheritance — instead of attaching policies to each user, you attach once to the group and every member inherits it. This is what we built on Tuesday.

**Pillar 2 — IAM Roles vs Users:** The key distinction covered today. Users have long-term credentials and are for individuals and applications with permanent access needs. Roles have temporary, short-lived credentials and are for AWS services and external users that need dynamic assumption — no permanent keys stored anywhere. The credential lifespan table in the diagram captures this perfectly: IAM User = Password/Keys (long-term), IAM Role = Temporary (short-lived).

**Pillar 3 — JSON Permission Policies:** Machine-readable documents that explicitly allow or deny actions on AWS resources. Every policy has an Effect (Allow/Deny), Action (what API call), and Resource (which ARN). This is what Wednesday's lab covered — writing the custom S3 read-only policy from scratch and testing it in the simulator.

**Pillar 4 — Critical Security Best Practices:** Three non-negotiables that apply to everything built this week — Principle of Least Privilege (only grant what is needed, nothing more), Enable MFA (done on Monday for the root account), and Regular Key Rotation (programmatic access keys should be rotated frequently to reduce exposure if leaked).

---