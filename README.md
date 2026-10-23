# CampaignLens: Investment Campaign Attribution & Analytics

PostgreSQL database and Python analytics for tracking which marketing campaigns bring in new investors and investments. It covers campaign attribution, the lead-to-customer funnel, advisor appointments and campaign ROI.

> 🚧 **Status:** In progress. The database is being built one module at a time. See [Progress](#-progress).

---

## 🚀 Quick Start: run the database on your computer

These steps take you from nothing to a running database with every schema and table created. Docker creates the empty database for you; then you run the project's SQL files in pgAdmin.

### What you need first

| Tool | Why | Get it |
|---|---|---|
| **Docker Desktop** | Runs PostgreSQL in a container, so you don't install PostgreSQL yourself | [docker.com](https://www.docker.com/products/docker-desktop/) (on Windows, use the WSL 2 option) |
| **Git** | Downloads (clones) this project | [git-scm.com](https://git-scm.com/downloads) |
| **pgAdmin 4** | A visual tool to run the SQL files and browse the database | [pgadmin.org](https://www.pgadmin.org/download/) |

Open **Docker Desktop** and wait until it says it is running before you continue.

> The commands below are for **Windows PowerShell** (for example the VS Code terminal). macOS/Linux users: use `cp` instead of `Copy-Item`; everything else is the same.

### Step 1: Download the project

```powershell
git clone https://github.com/Priyanshu2209/campaign-attribution-analytics.git
cd campaign-attribution-analytics
```

`git clone` copies the whole repository to your computer. `cd` moves the terminal into the project folder, where every later command must run.

### Step 2: Create your settings file (`.env`)

```powershell
Copy-Item .env.example .env
```

Then open `.env` and change `POSTGRES_PASSWORD` to a password of your own:

```
POSTGRES_USER=campaign_admin
POSTGRES_PASSWORD=change_me
POSTGRES_DB=campaign_db
POSTGRES_PORT=5433
```

| Setting | Meaning |
|---|---|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | The database login that gets created |
| `POSTGRES_DB` | The database name |
| `POSTGRES_PORT` | The port on **your** computer. `5433` avoids a clash with any PostgreSQL already installed on `5432` |

`.env` holds your password, so it is listed in `.gitignore` and never uploaded to GitHub. `.env.example` is the safe template that is uploaded.

> ⚠️ These settings are only used the **first** time the database is created. Changing them later has no effect unless you reset the database (see [Useful commands](#useful-commands)).

### Step 3: Start the database

```powershell
docker compose up -d
```

- `docker compose` reads `docker-compose.yml`, which describes the PostgreSQL 17 container.
- `up` creates and starts it; `-d` (detached) runs it in the background so your terminal stays free.
- The first time, Docker downloads the PostgreSQL image (about 150 MB), so it can take a minute.

**What this creates:** an empty PostgreSQL 17 database called `campaign_db`, with the login from your `.env`. It does **not** create schemas or tables yet; you do that in Step 6.

### Step 4: Check that it is running

```powershell
docker compose ps
```

The `STATUS` column should say **`healthy`** (wait a few seconds and try again if it says `starting`). If something looks wrong, `docker compose logs db` shows the database's messages.

### Step 5: Connect with pgAdmin

In pgAdmin: **right-click Servers → Register → Server**, then fill in:

| Tab | Setting | Value |
|---|---|---|
| General | Name | `Campaign DB (Docker)` |
| Connection | Host | `localhost` |
| Connection | Port | `5433` |
| Connection | Maintenance database | `campaign_db` |
| Connection | Username | `campaign_admin` |
| Connection | Password | *(the one in your `.env`)* |

Click **Save**. The server appears in the left panel.


### Useful commands

| Goal | Command |
|---|---|
| Start the database | `docker compose up -d` |
| Check status | `docker compose ps` |
| View logs | `docker compose logs db` |
| Open a SQL prompt | `docker compose exec db psql -U campaign_admin -d campaign_db` (type `\q` to leave) |
| Run one SQL file | `docker compose exec db psql -U campaign_admin -d campaign_db -f /db/<path>.sql` |
| Stop (data kept) | `docker compose stop` |
| Remove the container (data kept) | `docker compose down` |
| ⚠️ Reset everything (**deletes all data**) | `docker compose down -v`, then `docker compose up -d` and repeat Step 6 |

Paths like `/db/...` are **inside the container**: the project's `db/` folder is mounted there.


### Troubleshooting

| Problem | Fix |
|---|---|
| `error during connect` / Docker not found | Docker Desktop isn't running. Start it and wait until it's ready. |
| `port is already allocated` | Something else uses port 5433. Change `POSTGRES_PORT` in `.env` (e.g. `5434`) and run `docker compose up -d` again. |
| `password authentication failed` in pgAdmin | The password only applies on first creation. Use the original one, or reset with `docker compose down -v` (deletes data). |
| `schema "cust_relationship" does not exist` | The files were run out of order. Run `create_schemas.sql` first, then the others (Step 6). |
| `function public.set_updated_at() does not exist` | Run `db/functions/set_updated_at.sql` before the migrations. |

---

## 📌 The Business Problem

An investment company runs marketing campaigns every year (for example a bonus interest rate or a discount on advisor fees). The company wants to know **which campaigns actually bring in money**.

People respond to a campaign in two ways:

1. **New customers.** Someone hears about a campaign, books an appointment with an advisor, opens an account and invests.
2. **Existing customers.** A current customer sees a campaign and makes a new investment.

Visitors who show interest but don't invest are kept as **leads**, so the company can contact them about future campaigns, with their consent (Canada's anti-spam law, CASL).

The project answers questions like:

- How many new customers did each campaign bring in?
- Which investments from existing customers came from which campaign?
- Which campaign, and which channel, gives the best return on investment (ROI)?
- Where in the funnel do people drop off (visit → appointment → customer → investment)?
- How do advisors perform, and which customer segments respond to each campaign?

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| **PostgreSQL 17** | Relational database |
| **Docker & Docker Compose** | Runs PostgreSQL in a container, so anyone can start the project with one command |
| **pgAdmin 4** | Visual database client |
| **Python** *(planned)* | Data analysis and visualization |
| **Git & GitHub** | Version control |

---

## 📁 Project Structure

```
campaign-attribution-analytics/
├── db/                      # Everything PostgreSQL
│   ├── schemas/             # Creates all schemas (run first)
│   ├── functions/           # Shared functions & trigger functions (run second)
│   ├── migrations/          # Table definitions, run in order (001_, 002_, ...)
│   ├── views/               # Reporting views                       (planned)
│   └── seeds/               # Sample data                           (planned)
├── queries/                 # Business questions answered in SQL    (planned)
├── analysis/                # Python notebooks & reports            (planned)
├── docs/                    # Final ERD and design documents        (planned)
├── doc_history/             # Earlier versions of ERDs and design sheets (v1, v2, ...)
├── .env.example             # Template for database settings
├── docker-compose.yml       # PostgreSQL container setup
└── README.md
```

---

## 🗄️ Database Design

The design is built for a real Canadian investment firm (KYC, trusted contact person, CASL consent, accounts), with the campaign-tracking feature on top. It has **27 tables in 5 schemas**, plus a `reporting` schema for views.

### Schemas

Tables are grouped into **schemas** (like folders inside the database). This keeps related tables together and makes permissions easier: access can be granted per schema. Tables are always referenced with their schema name, e.g. `cust_relationship.customers`.

| Schema | Holds |
|---|---|
| `cust_relationship` | Who the client is: details, contacts, family and trusted contact, KYC, consent |
| `marketing` | Campaigns, channels, offers, spend, touchpoints |
| `sales` | Advisors, client-advisor assignments, appointments |
| `wealth` | Accounts, account holders, products, investments, payments, transactions |
| `audit` | Change history written by triggers |
| `reporting` | Views for analysis (funnel, ROI, advisor performance). Analysts get read-only access here |



### Design conventions

- Table and column names in `snake_case`; table names are plural.
- Primary keys: `BIGINT GENERATED ALWAYS AS IDENTITY`, named `<table_singular>_id`.
- Money: `NUMERIC(14,2)`, never floating point. Rates: `NUMERIC(6,3)` in percent.
- Timestamps: `TIMESTAMPTZ`. Every table has `created_at`, `updated_at` (kept current by a trigger) and `deleted_at` (soft delete: `NULL` = active).
- Status values: `VARCHAR` + `CHECK` constraints. Lookup tables only when they carry extra data.
- Readable constraint names (e.g. `chk_customers_kyc_status`) and an index on every foreign key.
- No stored values that go stale (age is calculated from `date_of_birth`).
- No sensitive numbers: never full SIN, ID or bank account numbers.
- History is kept as rows (e.g. a new address row with `lived_until` on the old one), not overwritten.

### Built: `cust_relationship.customers`

One table for everyone. `is_customer = false` is a visitor or lead; `true` is a client with an account. When a visitor converts, the **same row** is updated, so their history stays in one place.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `customer_id` | `BIGINT` | **PK**, generated always as identity | Internal unique ID |
| `first_name` / `last_name` | `VARCHAR(100)` | NOT NULL | Name |
| `email` | `VARCHAR(255)` | NOT NULL, unique (case-insensitive) | `John@Mail.com` and `john@mail.com` count as the same |
| `phone` | `VARCHAR(20)` | NULL | Main phone number |
| `is_customer` | `BOOLEAN` | NOT NULL, DEFAULT `false` | `true` = has an account |
| `customer_number` | `VARCHAR(20)` | UNIQUE; required only for customers | Readable ID, e.g. `CUS-000123` |
| `customer_type` | `VARCHAR(20)` | CHECK (`individual`, `corporate`); required for customers | Person or company |
| `date_of_birth` | `DATE` | Not in the future; required for individual customers | Age is calculated, never stored |
| `kyc_status` | `VARCHAR(20)` | CHECK (`pending`, `verified`, `expired`, `rejected`); required for customers | "Know Your Client" status |
| `acquired_campaign_id` | `BIGINT` | NULL, FK → `marketing.campaigns` *(added when that table exists)* | First-touch attribution |
| `first_seen_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `now()` | When the person first appeared |
| `became_customer_at` | `TIMESTAMPTZ` | Required for customers; ≥ `first_seen_at` | When the account was opened |
| `created_at` / `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `now()` | `updated_at` is set by a trigger |
| `deleted_at` | `TIMESTAMPTZ` | NULL | Soft delete. `NULL` = active |

**Business rules enforced by the database:**

- A customer **must** have `customer_number`, `customer_type`, `kyc_status` and `became_customer_at`; a visitor **can't** have a customer number, KYC status or conversion date.
- An individual customer must have a date of birth; it can't be in the future.
- `became_customer_at` can't be earlier than `first_seen_at`.
- No two people can share an email address (ignoring upper/lower case).

*Planned change:* a later migration adds `tcp_declined_at` (records that a client declined to name a trusted contact person).

---

## ✅ Progress

- [x] Repository, Docker + PostgreSQL 17 + pgAdmin setup
- [x] Schemas: `cust_relationship`, `marketing`, `sales`, `wealth`, `reporting`, `audit`
- [x] Full design of all 27 tables (ERD v1 in `doc_history/`)
- [ ] **Module 1: Customer relationship**
  - [x] `customers` table + `updated_at` trigger
  - [ ] `customer_addresses`, `customer_contacts`, `customer_related_persons`
  - [ ] `customer_financial_profiles`, `customer_employment`, `customer_identity_verifications`, `consents`
- [ ] Module 2: Sales (`advisors`, `customer_advisor_assignments`, `appointments`)
- [ ] Module 3: Marketing (`campaigns`, `channels`, `campaign_channels`, `campaign_offers`, `campaign_touchpoints`)
- [ ] Module 4: Wealth (`investment_products`, `accounts`, `account_holders`, `investments`, `payments`, `transactions`)
- [ ] Module 5: Audit log
- [ ] Final ERD in `docs/`
- [ ] Sample data, reporting views & business queries
- [ ] Python analysis

---

## 👤 Author

**Priyanshu Rana**
