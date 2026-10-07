# CampaignLens: Investment Campaign Attribution & Analytics

PostgreSQL database and Python analytics for tracking which marketing campaigns bring in new investors and investments. It covers campaign attribution, the lead-to-customer funnel, advisor appointments and campaign ROI.

> 🚧 **Status:** In progress. The database is being built one module at a time. See the [Progress](#-progress) section below.

---

## 📌 The Business Problem

An investment company runs marketing campaigns every year (for example, a bonus interest rate or a discount on advisor fees). The company wants to know **which campaigns actually bring in money**.

People respond to a campaign in two ways:

1. **New customers.** Someone hears about a campaign, books an appointment with an advisor, opens an account and invests.
2. **Existing customers.** A current customer sees a campaign and makes a new investment.

Visitors who show interest but don't invest are kept as **leads**, so the company can contact them about future campaigns (with their consent).

The goal of this project is to answer questions like:

- How many new customers did each campaign bring in?
- Which investments from existing customers came from which campaign?
- Which campaign, and which channel, gives the best return on investment (ROI)?
- Where in the funnel do people drop off (visit → appointment → customer → investment)?

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

## 🚀 Getting Started

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (on Windows, with WSL 2)
- Git
- *(Optional)* pgAdmin 4 or any PostgreSQL client

### 1. Clone the repository
```bash
git clone https://github.com/<your-username>/campaign-attribution-analytics.git
cd campaign-attribution-analytics
```

### 2. Create your `.env` file
Copy the example file, then set your own password:
```bash
cp .env.example .env
```
```
POSTGRES_USER=campaign_admin
POSTGRES_PASSWORD=change_me
POSTGRES_DB=campaign_db
POSTGRES_PORT=5433
```
> `.env` is listed in `.gitignore` and is never committed.

### 3. Start the database
```bash
docker compose up -d
docker compose ps        # status should show "healthy"
```

### 4. Connect
**From the terminal (psql inside the container):**
```bash
docker compose exec db psql -U campaign_admin -d campaign_db
```

**From pgAdmin (or any client):**

| Setting | Value |
|---|---|
| Host | `localhost` |
| Port | `5433` |
| Database | `campaign_db` |
| Username | `campaign_admin` |
| Password | *(from your `.env`)* |

> Port **5433** is used so it doesn't clash with a locally installed PostgreSQL on 5432.

### Useful commands
| Goal | Command |
|---|---|
| Start | `docker compose up -d` |
| Stop (data kept) | `docker compose stop` |
| View logs | `docker compose logs db` |
| Run a SQL file | `docker compose exec db psql -U campaign_admin -d campaign_db -f /db/<path-to-file>.sql` |
| ⚠️ Reset everything (deletes data) | `docker compose down -v` |

---

## 📁 Project Structure

```
campaign-attribution-analytics/
├── db/                    # Everything PostgreSQL
│   ├── migrations/        # Table definitions, run in order (001_, 002_, ...)
│   ├── functions/         # Stored functions & triggers        (planned)
│   ├── views/             # Reporting views                    (planned)
│   └── seeds/             # Sample data                        (planned)
├── queries/               # Business questions answered in SQL (planned)
├── analysis/              # Python notebooks & reports         (planned)
├── docs/                  # ERD and design decisions           (planned)
├── .env.example           # Template for database settings
├── docker-compose.yml     # PostgreSQL container setup
└── README.md
```

---

## 🗄️ Database Design

The database is designed module by module. Each table is documented below as it's built.

### Naming conventions
- Table and column names in `snake_case`; table names are plural (`customers`).
- Primary keys: `<table_singular>_id` (e.g. `customer_id`).
- Foreign keys use the same name as the key they point to.
- Every table has `created_at` and `updated_at`. Soft-deleted rows have a `deleted_at` value instead of being removed.
- Constraints have readable names (e.g. `chk_customers_kyc_status`).

---

### 👤 Module 1: Customers

#### `customers`

**Purpose:** Stores everyone who has **opened an account** with the company. A customer is created after a visitor meets an advisor and decides to invest.

Contact details (name, email, phone) live in a separate `persons` table *(planned)*, because visitors and leads have contact details too, before they ever become customers. The link is **one person → at most one customer record**.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `customer_id` | `BIGINT` | **PK**, generated always as identity | Internal unique ID |
| `person_id` | `BIGINT` | NOT NULL, UNIQUE, **FK → persons** *(planned)* | The person this customer record belongs to (1-to-1) |
| `customer_number` | `VARCHAR(20)` | NOT NULL, UNIQUE | Readable customer number shown to staff and customers, e.g. `CUS-000123` |
| `customer_type` | `VARCHAR(20)` | NOT NULL, CHECK (`individual`, `corporate`) | Whether the customer is a person or a company |
| `date_of_birth` | `DATE` | CHECK (not in the future) | Required for individuals. Age is **calculated**, never stored |
| `kyc_status` | `VARCHAR(20)` | NOT NULL, DEFAULT `pending`, CHECK (`pending`, `verified`, `expired`, `rejected`) | "Know Your Client" verification status, required before investing |
| `became_customer_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `now()` | When the account was opened |
| `acquired_campaign_id` | `BIGINT` | NULL, **FK → campaigns** *(planned)* | The campaign that brought this customer in. `NULL` = joined without a campaign |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `now()` | When the row was created |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `now()` | When the row was last changed |
| `deleted_at` | `TIMESTAMPTZ` | NULL | Soft delete. `NULL` = active customer |

**Business rules enforced by the database:**
- An individual customer **must** have a date of birth; a corporate customer doesn't need one.
- A date of birth can't be in the future.
- `kyc_status`, `customer_type` and `customer_number` can only hold valid values.
- One person can only have one customer record.

**Design decisions:**

| Decision | Reason |
|---|---|
| Numeric identity key (`BIGINT`) instead of a text ID | Smaller and faster for joins and indexes. `customer_number` is kept separately as the human-friendly ID |
| Contact details live in `persons`, not here | The same person can be a visitor → lead → customer. One record keeps their full history and avoids duplicates |
| `acquired_campaign_id` stored directly on the customer | Answers *"how many new customers did each campaign bring?"* with one simple query (**first-touch attribution**) |
| `TIMESTAMPTZ` for all timestamps | Stores the exact moment in time and handles Eastern Daylight / Standard Time correctly |
| Age is not stored | A stored age goes out of date; it's calculated from `date_of_birth` when needed |
| `CHECK` constraints instead of free text | Prevents typos and inconsistent values (e.g. `Verified` vs `verifed`) |
| Soft delete with `deleted_at` | Financial records shouldn't be physically deleted; this also records *when* it happened |

**Related customer tables** *(planned, same module)*:

| Table | Purpose |
|---|---|
| `customer_addresses` | Address history, one row per address (`valid_to` = `NULL` means current) |
| `customer_employment` | Employment history: status, occupation, industry, income |
| `customer_financial_profiles` | KYC summary: income, assets, liabilities, net worth, risk tolerance, investment goal |
| `customer_identity_verifications` | Record of how and when ID was verified (only the last 4 digits of the ID are stored) |

---

## ✅ Progress

- [x] Repository and project structure
- [x] Docker + PostgreSQL 17 + pgAdmin setup
- [ ] **Module 1: Customers**
  - [x] `customers` table design
  - [ ] `customers` migration (SQL)
  - [ ] Related customer tables (addresses, employment, financial profile, identity verification)
- [ ] Module 2: People & advisors (`persons`, `advisors`)
- [ ] Module 3: Campaigns (`campaigns`, `channels`, `campaign_channels`, `campaign_offers`)
- [ ] Module 4: Customer journey (`campaign_touchpoints`, `appointments`)
- [ ] Module 5: Investments & payments
- [ ] Module 6: Consent & communications
- [ ] ERD diagram
- [ ] Sample data
- [ ] Reporting views & business queries
- [ ] Python analysis

---

## 👤 Author

**Priyanshu Rana**
