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

### Step 6: Create the schemas and tables

Run the SQL files **in this order**. Order matters: tables live inside schemas, so the schemas must exist first.

| Order | File | Creates | Status |
|---|---|---|---|
| 1 | `db/schemas/create_schemas.sql` | All 6 schemas | ✅ available |
| 2 | `db/functions/*.sql` | Shared functions (e.g. the trigger that keeps `updated_at` current) | coming soon |
| 3 | `db/migrations/001_...`, `002_...` | The tables, in number order | coming soon |

Right now only step 1 exists; the function and table files are added here as each module is finished.

For each file, in pgAdmin:

1. Expand **Campaign DB (Docker) → Databases**, right-click **campaign_db → Query Tool**.
2. Click the **folder icon (Open File)** and choose the file from your cloned project folder. (Or copy the file's contents from GitHub and paste them in.)
3. Press **F5** (Execute). The **Messages** tab should show no errors.

When it has run, refresh **Schemas** in the left panel: you should see `cust_relationship`, `marketing`, `sales`, `wealth`, `reporting` and `audit`.

**Prefer the terminal?** The project's `db/` folder is available inside the container at `/db`, so a file can also be run like this:

```powershell
docker compose exec db psql -U campaign_admin -d campaign_db -f /db/schemas/create_schemas.sql
```

The file is safe to run again (`IF NOT EXISTS`), so running it twice by mistake does no harm.

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

### For developers: adding a new table

1. Create the next numbered file in `db/migrations/`, e.g. `002_create_customer_addresses.sql`. Always reference tables with their schema (`cust_relationship.customer_addresses`).
2. Run it in pgAdmin (Step 6) and test it.
3. Never edit a migration that is already pushed. Make a new one (e.g. `003_alter_...sql`) instead, so everyone can update their database the same way.

### Troubleshooting

| Problem | Fix |
|---|---|
| `error during connect` / Docker not found | Docker Desktop isn't running. Start it and wait until it's ready. |
| `port is already allocated` | Something else uses port 5433. Change `POSTGRES_PORT` in `.env` (e.g. `5434`) and run `docker compose up -d` again. |
| `password authentication failed` in pgAdmin | The password only applies on first creation. Use the original one, or reset with `docker compose down -v` (deletes data). |
| `schema "cust_relationship" does not exist` | The files were run out of order. Run `create_schemas.sql` first, then the others (Step 6). |

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
│   ├── functions/           # Shared functions & trigger functions   (coming soon)
│   ├── migrations/          # Table definitions, run in order        (coming soon)
│   ├── views/               # Reporting views                       (planned)
│   └── seeds/               # Sample data                           (planned)
├── queries/                 # Business questions answered in SQL    (planned)
├── analysis/                # Python notebooks & reports            (planned)
├── docs/                    # Final, current versions of design documents
│   └── data_dictionary/     # Data dictionary: every table, column, type and rule (Excel)
├── doc_history/             # All versions of ERDs and data dictionaries (v1, v2, ...)
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

### All tables

Every column, data type and rule is documented in the **data dictionary**: [`docs/data_dictionary/cust_relationship_data_dictionary.xlsx`](docs/data_dictionary/cust_relationship_data_dictionary.xlsx) (more schemas will be added).

Status: 🔨 in progress · 📝 designed · ⚪ optional (designed, may not be built)

| # | Schema | Table | Purpose | Status |
|---|---|---|---|---|
| 1 | cust_relationship | `customers` | Everyone: visitors, leads and customers (`is_customer`) | 🔨 |
| 2 | cust_relationship | `customer_addresses` | Address history (residential, mailing, business) | 📝 |
| 3 | cust_relationship | `customer_contacts` | All phone numbers and extra emails | 📝 |
| 4 | cust_relationship | `customer_related_persons` | Family, dependents, trusted contact person | 📝 |
| 5 | cust_relationship | `customer_financial_profiles` | KYC: income, assets, risk tolerance, next review | 📝 |
| 6 | cust_relationship | `customer_employment` | Employment history | 📝 |
| 7 | cust_relationship | `customer_identity_verifications` | How and when ID was verified (last 4 digits only) | 📝 |
| 8 | cust_relationship | `consents` | Marketing (CASL), privacy and e-delivery consent | 📝 |
| 9 | cust_relationship | `communications` | Emails and pop-ups sent, opened, clicked | ⚪ |
| 10 | cust_relationship | `corporate_details` | Extra data for corporate customers | ⚪ |
| 11 | cust_relationship | `corporate_owners` | Owners and beneficial owners of corporate customers | ⚪ |
| 12 | marketing | `campaigns` | Campaign, dates, budget, status | 📝 |
| 13 | marketing | `channels` | Lookup: website, email, social, event, referral | 📝 |
| 14 | marketing | `campaign_channels` | Campaign × channel, tracking code, spend | 📝 |
| 15 | marketing | `campaign_offers` | Fee discount or bonus interest | 📝 |
| 16 | marketing | `campaign_touchpoints` | Every known contact with a campaign (funnel stage 1) | 📝 |
| 17 | sales | `advisors` | Advisor details | 📝 |
| 18 | sales | `customer_advisor_assignments` | Which advisor serves which client, with history | 📝 |
| 19 | sales | `appointments` | Bookings and outcomes (funnel stage 2) | 📝 |
| 20 | sales | `advisor_availability` | Time slots for auto-assigning advisors | ⚪ |
| 21 | wealth | `investment_products` | Lookup: GICs, funds, ETFs, with rates and fees | 📝 |
| 22 | wealth | `accounts` | TFSA, RRSP, RRIF, FHSA, RESP, non-registered | 📝 |
| 23 | wealth | `account_holders` | Customers ↔ accounts (primary, joint, power of attorney) | 📝 |
| 24 | wealth | `investments` | What was bought, in which account, from which campaign | 📝 |
| 25 | wealth | `payments` | How each investment was paid | 📝 |
| 26 | wealth | `transactions` | Deposits, withdrawals, redemptions, fees, interest | 📝 |
| 27 | audit | `audit_log` | Every insert, update and delete, written by triggers | 📝 |

**How attribution works:** a new customer's first campaign is stored in `customers.acquired_campaign_id` (first-touch). Each investment by an existing customer stores its own `investments.campaign_id`. `campaign_touchpoints` keeps the full history for other attribution models in Python.

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

### First table: `cust_relationship.customers`

One table for everyone. `is_customer = false` is a visitor or lead; `true` is a client with an account. When a visitor converts, the **same row** is updated, so their history stays in one place.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `customer_id` | `BIGINT` | **PK**, generated always as identity | Internal unique ID |
| `first_name` / `last_name` | `VARCHAR(100)` | NOT NULL | Name |
| `email` | `VARCHAR(255)` | NOT NULL, unique (case-insensitive) | `John@Mail.com` and `john@mail.com` count as the same |
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
- [x] Data dictionary for `cust_relationship` (`docs/data_dictionary/`)
- [ ] **Module 1: Customer relationship**
  - [x] `customers` table designed
  - [ ] `customers` migration + `updated_at` trigger function (SQL files in the repo)
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
