# ☁️ AWS Cloud Journey — Week 1, Day 2: IAM Users, Groups & Policies

> **Roadmap:** AWS Cloud Networking → Cloud Network Security  
> **Phase:** 1 — Foundation  
> **Background:** Linux · CCNA Networking  
> **Date Completed:** May 2026

---

## 📋 Table of Contents

- [Overview](#overview)
- [Task 1 — Create First IAM User](#task-1--create-first-iam-user)
- [Task 2 — Attach AdministratorAccess Policy](#task-2--attach-administratoraccess-policy)
- [Task 3 — Create a Group](#task-3--create-a-group)
- [Task 4 — Add User to Group](#task-4--add-user-to-group)
- [CCNA Bridge](#ccna-bridge)
- [Key Takeaways](#key-takeaways)
- [Whats Next](#whats-next)

---

## Overview

This is **Day 2 of Week 1** of my AWS Cloud Networking roadmap. Today's focus was building out IAM identity structure — creating users, groups, and understanding how policies attach to both. This is directly equivalent to creating local user accounts and privilege levels on a Cisco 2911 router from my CCNA labs.

| Item | Detail |
|---|---|
| **Week** | Week 1 |
| **Day** | Tuesday |
| **Focus** | IAM Users, Groups & Policy Attachment |
| **Time Invested** | ~1.5 hours |
| **AWS Free Tier** | Active |
| **Status** | All tasks completed |

---

## Task 1 — Create First IAM User

### What I did
Created a new IAM user from the **IAM Dashboard → Users → Create User**. Enabled both **programmatic access** (for CLI) and **AWS Management Console access** with a custom password.

### Why this matters
The root account should never be used for daily work. Creating an IAM user with minimum permissions follows the **principle of least privilege** — the same concept as assigning `privilege 15` carefully in Cisco IOS rather than giving every user full router access.

### Steps taken
1. Go to **IAM → Users → Create User**
2. Set username: `lab-admin`
3. Enable **Console access** — set a custom password
4. Enable **Programmatic access** — download `.csv` with Access Key ID and Secret

### CLI equivalent
```bash
aws iam create-user --user-name lab-admin
aws iam create-login-profile --user-name lab-admin --password "YourP@ssword!" --password-reset-required
```

### Screenshot
> Replace with your actual screenshot

![IAM User Created](/Week1-tuesday/screenshorts/01_iam_user_created.png)
![IAM User Created](/Week1-tuesday/screenshorts/011_iam_user_created.png)
*New IAM user lab-admin successfully created*

---

## Task 2 — Attach AdministratorAccess Policy

### What I did
Attached the **AdministratorAccess** managed policy directly to the `lab-admin` user. This gives full access to all AWS services and resources.

### Why this matters
In a real environment, you would never attach `AdministratorAccess` directly to a user — you'd use a group instead. But for a personal lab account this is acceptable as a starting point, and understanding direct vs group-based policy attachment is important before moving to best practice patterns.

> **Best practice note:** Attaching policies directly to users becomes hard to manage at scale. Task 3 and 4 will move this to group-level attachment — the correct production pattern.

### Steps taken
1. Go to **IAM → Users → lab-admin → Add permissions**
2. Choose **Attach policies directly**
3. Search for and select **AdministratorAccess**
4. Review and confirm

### CLI equivalent
```bash
aws iam attach-user-policy \
  --user-name lab-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

```

![AdministratorAccess Attached](/Week1-tuesday/screenshorts/022_admin_policy_attached.png)
![AdministratorAccess Attached](/Week1-tuesday/screenshorts/02_admin_policy_attached.png)

*AdministratorAccess policy attached to lab-admin user*

---

## Task 3 — Create a Group

### What I did
Created an IAM group named **Developers** with the **PowerUserAccess** policy attached — giving broad permissions but excluding IAM management (so group members cannot create new users or change permissions).

### Why this matters
Groups are the correct way to manage permissions at scale. Instead of attaching policies to each user individually, you define a group, attach policies once, and then add or remove users. Changing a group's permissions instantly applies to every member.

This is equivalent to using **privilege levels** in Cisco IOS — you define what a privilege level can do once, then assign users to that level.

### Groups created

| Group Name | Policy Attached | Purpose |
|---|---|---|
| `Developers` | PowerUserAccess | Devs who need AWS access but not IAM control |
| `NetworkAdmins` | AdministratorAccess | Full access for network and cloud admins |
| `ReadOnly` | ReadOnlyAccess | Auditors or junior team members |

### Steps taken
1. Go to **IAM → User Groups → Create Group**
2. Group name: `Developers`
3. Attach policy: **PowerUserAccess**
4. Create group
5. Repeat for `NetworkAdmins` and `ReadOnly`

### CLI equivalent
```bash
aws iam create-group --group-name Developers

aws iam attach-group-policy \
  --group-name Developers \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Verify
aws iam list-attached-group-policies --group-name Developers
```


![IAM Groups Created](/Week1-tuesday/screenshorts/03_groups_created.png)
![IAM Groups Created](/Week1-tuesday/screenshorts/033_groups_created.png)
![IAM Groups Created](/Week1-tuesday/screenshorts/0333_groups_created.png)
*Developers, NetworkAdmins, and ReadOnly groups created*

---

## Task 4 — Add User to Group

### What I did
Added the `lab-admin` user to the **NetworkAdmins** group and removed the directly attached `AdministratorAccess` policy — moving to group-based permission management as best practice.

### Why this matters
Permissions now flow through group membership, not direct attachment. If `lab-admin` ever needs to be restricted, I change the group policy in one place — not on every individual user. This is how real cloud environments manage identity at scale.

### Steps taken
1. Go to **IAM → User Groups → NetworkAdmins → Add users**
2. Select `lab-admin` → Add to group
3. Go to **IAM → Users → lab-admin → Permissions**
4. Remove directly attached `AdministratorAccess` policy
5. Verify permissions are now inherited from group only

### CLI equivalent
```bash
# Add user to group
aws iam add-user-to-group --user-name lab-admin --group-name NetworkAdmins

# Remove direct policy (cleanup)
aws iam detach-user-policy \
  --user-name lab-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Verify group membership
aws iam get-group --group-name NetworkAdmins
```

### Screenshot
> Replace with your actual screenshot

![User Added to Group](/Week1-tuesday/screenshorts/04_user_in_group.png)
![User Added to Group](/Week1-tuesday/screenshorts/044_user_in_group.png)
*lab-admin added to NetworkAdmins — permissions now inherited from group*

![User Added to Group](/Week1-tuesday/screenshorts/0444_user_in_group.png)
*IAM permissions tab showing policy inherited via group, not directly attached*

---

## CCNA Bridge

This is where my CCNA background directly applies. Here is the mapping between what I configured on the Cisco 2911 and what I did in IAM today:

| Cisco IOS (2911) | AWS IAM Equivalent |
|---|---|
| `username admin privilege 15 secret Cisco123` | IAM user `lab-admin` + AdministratorAccess policy |
| `username readonly privilege 1 secret Cisco123` | IAM user + ReadOnlyAccess policy |
| Privilege level (1–15) | IAM policy with specific allowed actions |
| `line vty 0 4 / login local` | IAM console login profile + MFA |
| Assigning a user to a group config | Adding user to IAM group |
| `show users` | `aws iam list-users` |
| `show privilege` | `aws iam list-attached-user-policies --user-name lab-admin` |

**Key insight:** IAM groups are more powerful than Cisco privilege levels because you can define granular, service-level permissions per group — not just a numbered tier. A user in `Developers` can be allowed to launch EC2 but denied access to IAM or billing with a single policy.

---

## Key Takeaways

```
Created IAM user lab-admin with console and programmatic access
Attached AdministratorAccess — then moved to group-based model (best practice)
Created 3 groups: Developers, NetworkAdmins, ReadOnly
Permissions now flow through group membership — easier to manage at scale
CCNA privilege levels map directly to IAM policies — same concept, more granular
```

### One thing I learned
The difference between **managed policies** (AWS pre-built, reusable across users and groups) and **inline policies** (embedded directly into a single user or group, not reusable). For lab work, managed policies are fine. In production you would write custom policies with only exactly the permissions needed.

### One thing that was different from CCNA
In Cisco IOS, privilege levels are a simple numbered tier from 1 to 15. In IAM, you write JSON policies that allow or deny specific API actions on specific resources. It is far more granular — but also more complex to write correctly. Wednesday's lab covers this.

---

## Whats Next

| Day | Focus |
|---|---|
| **Wednesday** | Writing custom IAM policies in JSON + using the IAM policy simulator |
| **Thursday** | IAM roles — when to use roles vs users, attaching roles to EC2 |
| **Friday** | AWS CLI setup on Linux + authenticating with named profiles |
| **Saturday** | Full IAM lab rebuild from scratch (no guide) |
| **Sunday** | Review + AWS Well-Architected Security reading |

---

## Resources Used

- [AWS IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS CLI IAM Reference](https://docs.aws.amazon.com/cli/latest/reference/iam/)
- [AWS Policy Simulator](https://policysim.aws.amazon.com/)

---

## Screenshots Folder Structure

```
Week1-tuesday/
├── screenshorts/
│   ├── 01_iam_user_created.png
│   ├── 011_iam_user_created.png
│   ├── 02_admin_policy_attached.png
│   ├── 022_admin_policy_attached.png
│   ├── 03_groups_created.png
│   ├── 033_groups_created.png
│   ├── 0333_groups_created.png
│   ├── 04_user_in_group.png
│   ├── 044_user_in_group.png
│   └── 05_permissions_from_group.png
└── week1_tuesday_iam_users_groups.md
```



---

*Part of my AWS Cloud Networking roadmap — from Linux & CCNA background to Cloud Network Security Engineer.*  
*Follow along as I document each week of labs and learning.*
