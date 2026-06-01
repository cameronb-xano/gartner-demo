import { useEffect, useState } from "react";
import {
  clearPersistedSession,
  loadPersistedSession,
  persistSession,
} from "./lib/authStorage";
import { workspaces } from "./lib/demoData";
import {
  type Claim,
  type Claim360,
  type Customer,
  type Invoice,
  type ListResponse,
  type Notification,
  xanoClient,
} from "./lib/xanoClient";
import type { AuthSession, WorkspaceId } from "./types/demo";

type Page = "claims" | "customers" | "payments" | "messages" | "systems";

type AppData = {
  claims: Claim[];
  claimsMeta: ListResponse<Claim> | null;
  customers: Customer[];
  customersMeta: ListResponse<Customer> | null;
  invoices: Invoice[];
  invoicesMeta: ListResponse<Invoice> | null;
  notifications: Notification[];
  notificationsMeta: ListResponse<Notification> | null;
};

const navItems: Array<{ id: Page; label: string; description: string }> = [
  { id: "claims", label: "Claims", description: "Customer claims workspace" },
  { id: "customers", label: "Customers", description: "Policyholder records" },
  { id: "payments", label: "Payouts", description: "Escalation & payouts" },
  { id: "messages", label: "Events", description: "Escalation telemetry" },
  { id: "systems", label: "Systems", description: "Insurance workspace map" },
];

const workspaceStyles: Record<WorkspaceId, string> = {
  customerClaims: "bg-blue-50 text-blue-700 ring-blue-200",
  policyData: "bg-emerald-50 text-emerald-700 ring-emerald-200",
  rulesDecisioning: "bg-violet-50 text-violet-700 ring-violet-200",
  escalationPayouts: "bg-amber-50 text-amber-700 ring-amber-200",
};

function App() {
  const [session, setSessionState] = useState<AuthSession | null>(() =>
    loadPersistedSession(),
  );

  function commitSession(next: AuthSession | null) {
    if (next) persistSession(next);
    else clearPersistedSession();
    setSessionState(next);
  }
  const [activePage, setActivePage] = useState<Page>("claims");
  const [selectedClaimId, setSelectedClaimId] = useState<number | null>(null);
  const [claim360, setClaim360] = useState<Claim360 | null>(null);
  const [data, setData] = useState<AppData>({
    claims: [],
    claimsMeta: null,
    customers: [],
    customersMeta: null,
    invoices: [],
    invoicesMeta: null,
    notifications: [],
    notificationsMeta: null,
  });
  const [loadingPage, setLoadingPage] = useState<Page | null>(() =>
    session ? "claims" : null,
  );
  const [loadingClaim360, setLoadingClaim360] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isEscalating, setIsEscalating] = useState(false);

  useEffect(() => {
    if (!session) return;
    void loadPage("claims", session.token);
  }, [session]);

  useEffect(() => {
    if (!session) return;
    void loadPage(activePage, session.token);
  }, [activePage, session]);

  useEffect(() => {
    if (!session || selectedClaimId == null) return;
    void loadClaim360(session.token, selectedClaimId);
  }, [session, selectedClaimId]);

  async function loadPage(page: Page, token: string) {
    setLoadingPage(page);
    setError(null);

    try {
      const minimumLoading = wait(700);
      if (page === "claims") {
        const claimsMeta = await xanoClient.listClaims(token);
        const claims = claimsMeta.items ?? [];
        const recordingClaim = claims.find((claim) => Number(claim.amount_requested ?? 0) >= 5000);
        setData((current) => ({ ...current, claims, claimsMeta }));
        setSelectedClaimId((current) => current ?? recordingClaim?.id ?? claims[0]?.id ?? null);
      }

      if (page === "customers") {
        const customersMeta = await xanoClient.listCustomers(token);
        setData((current) => ({
          ...current,
          customers: customersMeta.items ?? [],
          customersMeta,
        }));
      }

      if (page === "payments") {
        const invoicesMeta = await xanoClient.listInvoices();
        setData((current) => ({
          ...current,
          invoices: invoicesMeta.items ?? [],
          invoicesMeta,
        }));
      }

      if (page === "messages") {
        const notificationsMeta = await xanoClient.listNotifications();
        setData((current) => ({
          ...current,
          notifications: notificationsMeta.items ?? [],
          notificationsMeta,
        }));
      }
      await minimumLoading;
    } catch (caught) {
      const msg = errorMessage(caught);
      if (token && isAuthFailureMessage(msg)) {
        commitSession(null);
        return;
      }
      setError(msg);
    } finally {
      setLoadingPage(null);
    }
  }

  async function loadClaim360(token: string, claimId: number) {
    setError(null);
    setLoadingClaim360(true);
    try {
      const [nextClaim360] = await Promise.all([
        xanoClient.getClaim360(claimId, token),
        wait(700),
      ]);
      setClaim360(nextClaim360);
    } catch (caught) {
      const msg = errorMessage(caught);
      if (isAuthFailureMessage(msg)) {
        commitSession(null);
        return;
      }
      setClaim360(null);
      setError(msg);
    } finally {
      setLoadingClaim360(false);
    }
  }

  async function escalateSelectedClaim() {
    if (!session || selectedClaimId == null) return;
    setIsEscalating(true);
    setError(null);

    try {
      const [escalation] = await Promise.all([
        xanoClient.escalateClaim(
          selectedClaimId,
          session.token,
          "Specialist review requested from customer claims workspace",
        ),
        wait(900),
      ]);
      setData((current) => {
        const claims = current.claims.map((claim) =>
          claim.id === escalation.claim.id
            ? { ...claim, ...escalation.claim, source: claim.source }
            : claim,
        );

        return {
          ...current,
          claims,
          claimsMeta: current.claimsMeta
            ? { ...current.claimsMeta, items: claims }
            : current.claimsMeta,
        };
      });
      await loadClaim360(session.token, selectedClaimId);
    } catch (caught) {
      const msg = escalationErrorMessage(caught);
      if (isAuthFailureMessage(msg)) {
        commitSession(null);
        return;
      }
      setError(msg);
    } finally {
      setIsEscalating(false);
    }
  }

  if (!session) return <LoginScreen onLogin={(s) => commitSession(s)} />;

  return (
    <main className="min-h-screen bg-slate-100 text-slate-950">
      <div className="grid min-h-screen lg:grid-cols-[290px_1fr]">
        <Sidebar
          activePage={activePage}
          session={session}
          onNavigate={setActivePage}
          onSignOut={() => commitSession(null)}
        />
        <section className="flex min-w-0 flex-col">
          <Topbar
            activePage={activePage}
            session={session}
            onSignOut={() => commitSession(null)}
          />
          <div className="flex flex-1 flex-col gap-6 p-5 md:p-8">
            {error && <ErrorBanner message={error} />}
            <PageHeader
              activePage={activePage}
              data={data}
              loading={loadingPage === activePage}
            />
            {activePage === "claims" && (
              <ClaimsPage
                claims={data.claims}
                claimsMeta={data.claimsMeta}
                selectedClaimId={selectedClaimId}
                claim360={claim360}
                loading={loadingPage === "claims"}
                loadingClaim360={loadingClaim360}
                isEscalating={isEscalating}
                onSelect={setSelectedClaimId}
                onEscalate={() => void escalateSelectedClaim()}
              />
            )}
            {activePage === "customers" && (
              <CustomersPage
                customers={data.customers}
                meta={data.customersMeta}
                loading={loadingPage === "customers"}
              />
            )}
            {activePage === "payments" && (
              <PaymentsPage
                invoices={data.invoices}
                meta={data.invoicesMeta}
                loading={loadingPage === "payments"}
              />
            )}
            {activePage === "messages" && (
              <EventsPage
                notifications={data.notifications}
                meta={data.notificationsMeta}
                loading={loadingPage === "messages"}
              />
            )}
            {activePage === "systems" && <SystemsPage claim360={claim360} />}
          </div>
        </section>
      </div>
    </main>
  );
}

function LoginScreen({ onLogin }: { onLogin: (session: AuthSession) => void }) {
  const [mode, setMode] = useState<"login" | "signup">("login");
  const [name, setName] = useState("Avery Stone");
  const [email, setEmail] = useState("claims.lead@helios.example");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const nextSession =
        mode === "login"
          ? await xanoClient.login({ email, password })
          : await xanoClient.signup({ name, email, password, role: "supervisor" });
      onLogin(nextSession);
    } catch (caught) {
      setError(errorMessage(caught));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="grid min-h-screen bg-slate-950 text-white lg:grid-cols-[1fr_520px]">
      <section className="flex flex-col justify-between p-8 md:p-12">
        <Brand />
        <div className="max-w-3xl py-16">
          <p className="text-sm font-semibold uppercase tracking-[0.28em] text-blue-200">
            Insurance claims platform
          </p>
          <h1 className="mt-5 text-5xl font-semibold tracking-tight md:text-7xl">
            Route claims across four connected workspaces.
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
            Authenticate against Xano, then review claims, policy context,
            business decisions, and escalation telemetry from one application.
          </p>
        </div>
        <div className="grid max-w-3xl gap-4 md:grid-cols-3">
          <HeroStat label="Backend" value="Xano" />
          <HeroStat label="Workspaces" value="4" />
          <HeroStat label="App shell" value="Live" />
        </div>
      </section>

      <section className="flex items-center justify-center bg-white p-6 text-slate-950 md:p-10">
        <form
          onSubmit={handleSubmit}
          className="w-full max-w-md rounded-[2rem] border border-slate-200 p-8 shadow-2xl"
        >
          <p className="text-sm font-semibold uppercase tracking-[0.22em] text-blue-600">
            {mode === "login" ? "Sign in" : "Create account"}
          </p>
          <h2 className="mt-3 text-3xl font-semibold">Welcome back</h2>
          <p className="mt-3 text-sm leading-6 text-slate-500">
            Uses the live `gartner-claims-auth` API.
          </p>
          {error && <ErrorInline message={error} />}
          {mode === "signup" && (
            <TextField label="Name" value={name} onChange={setName} autoComplete="name" />
          )}
          <TextField
            label="Email"
            value={email}
            onChange={setEmail}
            type="email"
            autoComplete="email"
          />
          <TextField
            label="Password"
            value={password}
            onChange={setPassword}
            type="password"
            autoComplete={mode === "login" ? "current-password" : "new-password"}
            placeholder="Minimum 8 characters"
          />
          <button
            type="submit"
            disabled={isSubmitting || password.length < 8}
            className="mt-6 w-full rounded-2xl bg-blue-600 px-4 py-3 font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-slate-400"
          >
            {isSubmitting
              ? "Contacting Xano..."
              : mode === "login"
                ? "Sign in"
                : "Create account"}
          </button>
          <button
            type="button"
            onClick={() => {
              setError(null);
              setMode(mode === "login" ? "signup" : "login");
            }}
            className="mt-4 w-full text-sm font-semibold text-blue-700"
          >
            {mode === "login"
              ? "Need an operator account? Create one"
              : "Already have an account? Sign in"}
          </button>
        </form>
      </section>
    </main>
  );
}

function Sidebar({
  activePage,
  session,
  onNavigate,
  onSignOut,
}: {
  activePage: Page;
  session: AuthSession;
  onNavigate: (page: Page) => void;
  onSignOut: () => void;
}) {
  return (
    <aside className="hidden border-r border-slate-200 bg-slate-950 p-6 text-white lg:block">
      <Brand />
      <nav className="mt-10 space-y-2">
        {navItems.map((item) => (
          <button
            key={item.id}
            type="button"
            onClick={() => onNavigate(item.id)}
            className={`w-full rounded-2xl px-4 py-3 text-left transition ${
              item.id === activePage
                ? "bg-white text-slate-950"
                : "text-slate-300 hover:bg-white/10"
            }`}
          >
            <span className="block text-sm font-semibold">{item.label}</span>
            <span className="mt-0.5 block text-xs opacity-70">
              {item.description}
            </span>
          </button>
        ))}
      </nav>
      <div className="mt-10 rounded-3xl border border-white/10 bg-white/5 p-4">
        <p className="text-sm font-semibold">Signed-in operator</p>
        <p className="mt-2 break-all text-sm text-slate-300">{session.user.email}</p>
        <p className="mt-1 text-xs capitalize text-slate-500">{session.user.role}</p>
        <button
          type="button"
          onClick={onSignOut}
          className="mt-4 w-full rounded-2xl border border-white/20 bg-white/10 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-white/20"
        >
          Sign out
        </button>
      </div>
    </aside>
  );
}

function Brand() {
  return (
    <div className="flex items-center gap-3">
      <div className="grid size-12 place-items-center rounded-2xl bg-blue-500 text-lg font-bold">
        N
      </div>
      <div>
        <p className="text-xl font-semibold">Northstar Claims</p>
        <p className="text-sm text-slate-400">Insurance Platform</p>
      </div>
    </div>
  );
}

function Topbar({
  activePage,
  session,
  onSignOut,
}: {
  activePage: Page;
  session: AuthSession;
  onSignOut: () => void;
}) {
  return (
    <header className="sticky top-0 z-10 border-b border-slate-200 bg-white/90 px-5 py-4 backdrop-blur md:px-8">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-sm text-slate-500">Northstar insurance operations</p>
          <h1 className="text-2xl font-semibold tracking-tight capitalize">
            {pageLabel(activePage)}
          </h1>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <span className="rounded-full bg-emerald-100 px-3 py-1 text-sm font-semibold text-emerald-700">
            Live backend
          </span>
          <button
            type="button"
            onClick={onSignOut}
            className="rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 lg:hidden"
          >
            Sign out
          </button>
          <div className="rounded-full bg-slate-950 px-4 py-2 text-sm font-semibold text-white">
            {session.user.name}
          </div>
        </div>
      </div>
    </header>
  );
}

function PageHeader({
  activePage,
  data,
  loading,
}: {
  activePage: Page;
  data: AppData;
  loading: boolean;
}) {
  const totals = {
    claims: data.claimsMeta?.itemsTotal ?? data.claims.length,
    customers: data.customersMeta?.itemsTotal ?? data.customers.length,
    payments: data.invoicesMeta?.itemsTotal ?? data.invoices.length,
    messages: data.notificationsMeta?.itemsTotal ?? data.notifications.length,
    systems: workspaces.length,
  };

  return (
    <section className="rounded-[2rem] bg-slate-950 p-8 text-white shadow-2xl">
      <p className="inline-flex items-center gap-3 text-sm font-semibold uppercase tracking-[0.28em] text-blue-200">
        {loading && <LoadingSpinner tone="light" />}
        <span>{loading ? "Loading from Xano" : "Live Xano data"}</span>
      </p>
      <h2 className="mt-3 text-4xl font-semibold tracking-tight capitalize">
        {pageLabel(activePage)}
      </h2>
      <p className="mt-3 max-w-2xl text-sm leading-6 text-slate-300">
        {pageDescription(activePage)}
      </p>
      <div className="mt-6 grid max-w-4xl gap-4 md:grid-cols-3">
        <HeroStat label="Records" value={String(totals[activePage])} />
        <HeroStat label="API host" value="xjik-uiot" />
        <HeroStat label="Mode" value="Recorded flow" />
      </div>
    </section>
  );
}

function ClaimsPage({
  claims,
  claimsMeta,
  selectedClaimId,
  claim360,
  loading,
  loadingClaim360,
  isEscalating,
  onSelect,
  onEscalate,
}: {
  claims: Claim[];
  claimsMeta: ListResponse<Claim> | null;
  selectedClaimId: number | null;
  claim360: Claim360 | null;
  loading: boolean;
  loadingClaim360: boolean;
  isEscalating: boolean;
  onSelect: (claimId: number) => void;
  onEscalate: () => void;
}) {
  const selectedClaim = claim360?.claim ?? claims.find((claim) => claim.id === selectedClaimId);
  const requestedTotal = claims.reduce(
    (sum, claim) => sum + Number(claim.amount_requested ?? 0),
    0,
  );

  return (
    <section className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_420px]">
      <div className="flex min-w-0 flex-col gap-6">
        <div className="grid gap-4 md:grid-cols-3">
          <Metric label="Loaded claims" value={loading ? "Loading" : String(claims.length)} loading={loading} />
          <Metric label="Source" value={claimsMeta?.source ?? "Snowflake"} />
          <Metric label="Loaded requested" value={formatCurrency(requestedTotal)} />
        </div>
        <DataCard title="Snowflake customer claims" subtitle="GET /api:gartner-policy-data/claims">
          <DataTable
            loading={loading || claimsMeta == null}
            loadingText="Loading Snowflake-backed claims..."
            emptyText="No claims returned from Xano."
            rows={claims}
            columns={["Claim", "Type", "Status", "Priority", "Queue", "Requested"]}
            renderRow={(claim) => (
              <tr
                key={claim.id}
                onClick={() => onSelect(claim.id)}
                className={`cursor-pointer transition hover:bg-slate-50 ${
                  claim.id === selectedClaimId ? "bg-blue-50/70" : ""
                }`}
              >
                <Cell strong>{claim.claim_number}</Cell>
                <Cell>{claim.claim_type}</Cell>
                <Cell><StatusPill value={claim.status} /></Cell>
                <Cell>{claim.priority}</Cell>
                <Cell>{formatQueue(claim.assigned_queue)}</Cell>
                <Cell align="right" strong>{formatCurrency(claim.amount_requested)}</Cell>
              </tr>
            )}
          />
        </DataCard>
        <ClaimDetail
          claim={selectedClaim}
          claim360={claim360}
          loading={loadingClaim360}
          isEscalating={isEscalating}
          onEscalate={onEscalate}
        />
      </div>
      <aside className="flex flex-col gap-6">
        <AutoApprovalRule />
        <CustomerSummary claim360={claim360} />
        <ServiceActivity claim360={claim360} />
      </aside>
    </section>
  );
}

function CustomersPage({
  customers,
  meta,
  loading,
}: {
  customers: Customer[];
  meta: ListResponse<Customer> | null;
  loading: boolean;
}) {
  return (
    <div className="space-y-6">
      <div className="grid gap-4 md:grid-cols-3">
        <Metric label="Loaded customers" value={loading ? "Loading" : String(customers.length)} />
        <Metric label="Backend total" value={String(meta?.itemsTotal ?? "-")} />
        <Metric label="API" value="gartner-claims" />
      </div>
      <DataCard title="Customers" subtitle="GET /api:gartner-claims/customers">
        <DataTable
          loading={loading}
          loadingText="Loading policyholder records..."
          emptyText="No customers returned from Xano."
          rows={customers}
          columns={["Name", "Email", "Phone", "Policy", "Created"]}
          renderRow={(customer) => (
            <tr key={customer.id} className="hover:bg-slate-50">
              <Cell strong>{customerName(customer)}</Cell>
              <Cell>{customer.email ?? "-"}</Cell>
              <Cell>{customer.phone ?? "-"}</Cell>
              <Cell>{customer.policy_number ?? "-"}</Cell>
              <Cell>{formatDate(customer.created_at)}</Cell>
            </tr>
          )}
        />
      </DataCard>
    </div>
  );
}

function PaymentsPage({
  invoices,
  meta,
  loading,
}: {
  invoices: Invoice[];
  meta: ListResponse<Invoice> | null;
  loading: boolean;
}) {
  const total = invoices.reduce((sum, invoice) => sum + Number(invoice.amount ?? 0), 0);

  return (
    <div className="space-y-6">
      <div className="grid gap-4 md:grid-cols-3">
        <Metric label="Loaded invoices" value={loading ? "Loading" : String(invoices.length)} />
        <Metric label="Backend total" value={String(meta?.itemsTotal ?? "-")} />
        <Metric label="Loaded value" value={formatCurrency(total)} />
      </div>
      <DataCard title="Payout ledger" subtitle="Escalation & Payouts workspace">
        <DataTable
          loading={loading}
          loadingText="Loading payout records..."
          emptyText="No invoices returned from Xano."
          rows={invoices}
          columns={["Invoice", "Claim", "Direction", "Status", "Due", "Amount"]}
          renderRow={(invoice) => (
            <tr key={invoice.id} className="hover:bg-slate-50">
              <Cell strong>#{invoice.id}</Cell>
              <Cell>{invoice.claim_ref ?? "-"}</Cell>
              <Cell>{invoice.direction ?? "-"}</Cell>
              <Cell><StatusPill value={invoice.status ?? "unknown"} /></Cell>
              <Cell>{formatDate(invoice.due_at)}</Cell>
              <Cell align="right" strong>{formatCurrency(invoice.amount)}</Cell>
            </tr>
          )}
        />
      </DataCard>
    </div>
  );
}

function EventsPage({
  notifications,
  meta,
  loading,
}: {
  notifications: Notification[];
  meta: ListResponse<Notification> | null;
  loading: boolean;
}) {
  return (
    <div className="space-y-6">
      <div className="grid gap-4 md:grid-cols-3">
        <Metric label="Loaded events" value={loading ? "Loading" : String(notifications.length)} />
        <Metric label="Backend total" value={String(meta?.itemsTotal ?? "-")} />
        <Metric label="Workspace" value="Escalation & Payouts" />
      </div>
      <DataCard title="Escalation event log" subtitle="GET /api:gartner-escalation-payouts/events">
        <DataTable
          loading={loading}
          loadingText="Loading Datadog-style escalation events..."
          emptyText="No escalation events returned from Xano."
          rows={notifications}
          columns={["Claim", "Route", "Priority", "Datadog event", "Metric"]}
          renderRow={(notification) => (
            <tr key={notification.id} className="hover:bg-slate-50">
              <Cell strong>{notification.claim_number ?? `Claim ${notification.claim_id ?? notification.id}`}</Cell>
              <Cell>{notification.route?.replaceAll("_", " ") ?? "-"}</Cell>
              <Cell><StatusPill value={notification.priority ?? "unknown"} /></Cell>
              <Cell>{notification.datadog_event ?? "claim.escalated"}</Cell>
              <Cell>{notification.datadog_metric ?? "claims.escalations.routed"}</Cell>
            </tr>
          )}
        />
      </DataCard>
    </div>
  );
}

function SystemsPage({ claim360 }: { claim360: Claim360 | null }) {
  return (
    <section className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_420px]">
      <DataCard title="Insurance platform map" subtitle="Four workspaces for the recorded claims story">
        <div className="grid gap-4 md:grid-cols-2">
          {workspaces.map((workspace) => (
            <article
              key={workspace.id}
              className={`rounded-3xl p-5 ring-1 ${workspaceStyles[workspace.id]}`}
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h3 className="font-semibold">{workspace.name}</h3>
                  <p className="mt-2 text-sm opacity-80">{workspace.role}</p>
                </div>
                <span className="rounded-full bg-white/70 px-3 py-1 text-xs font-semibold">
                  {workspace.endpointCount} APIs
                </span>
              </div>
              <p className="mt-4 font-mono text-xs">api:{workspace.canonical}</p>
            </article>
          ))}
        </div>
      </DataCard>
      <ServiceActivity claim360={claim360} />
    </section>
  );
}

function ClaimDetail({
  claim,
  claim360,
  loading,
  isEscalating,
  onEscalate,
}: {
  claim?: Claim;
  claim360: Claim360 | null;
  loading: boolean;
  isEscalating: boolean;
  onEscalate: () => void;
}) {
  const policyContext = policyContextFromClaim360(claim360);
  const weatherContext = policyContext.summary ?? claim?.summary ?? "";
  const hasWeatherSignal = /weather|storm|roof|water|catastrophe/i.test(weatherContext);

  return (
    <DataCard
      title={claim ? `Claim ${claim.claim_number}` : "Select a claim"}
      subtitle={claim?.summary ?? "Choose a claim to load the 360 view"}
      action={
        <button
          type="button"
          onClick={onEscalate}
          disabled={!claim || isEscalating}
          className="rounded-2xl bg-blue-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-slate-400"
        >
          {isEscalating ? (
            <span className="inline-flex items-center gap-2">
              <LoadingSpinner tone="light" />
              Escalating...
            </span>
          ) : (
            "Escalate claim"
          )}
        </button>
      }
    >
      {(loading || isEscalating) && (
        <LoadingPanel text="Loading claim 360, Snowflake context, and rules decision..." />
      )}
      <div className="grid gap-4 md:grid-cols-4">
        <Metric label="Requested" value={claim ? formatCurrency(claim.amount_requested) : "-"} />
        <Metric
          label="Approved"
          value={claim?.amount_approved ? formatCurrency(claim.amount_approved) : "-"}
        />
        <Metric
          label="Assigned queue"
          value={formatQueue(claim?.assigned_queue)}
        />
        <Metric label="Timeline events" value={String(claim360?.timeline?.length ?? 0)} />
      </div>
      <div className="mt-6 rounded-3xl border border-amber-200 bg-amber-50 p-4">
        <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-amber-700">
              Snowflake claim context
            </p>
            <p className="mt-2 text-sm font-semibold text-slate-900">
              {hasWeatherSignal
                ? "Weather signal detected for this property claim"
                : "No weather signal detected"}
            </p>
            <p className="mt-1 text-sm text-slate-600">
              {weatherContext || "Select a claim to load Snowflake policy context."}
            </p>
          </div>
          <span className="shrink-0 rounded-full bg-white px-3 py-1 text-xs font-semibold text-amber-700 ring-1 ring-amber-200">
            {policyContext.coverage_tier ?? "Snowflake"}
          </span>
        </div>
      </div>
      <div className="mt-6 space-y-3">
        {(claim360?.timeline ?? []).slice(0, 5).map((event) => (
          <article key={event.id} className="rounded-2xl bg-slate-50 p-4 text-sm">
            <div className="flex items-center justify-between gap-3">
              <p className="font-semibold capitalize">{event.event_type.replaceAll("_", " ")}</p>
              <p className="text-xs text-slate-400">{formatDate(event.created_at)}</p>
            </div>
            <p className="mt-1 text-slate-600">{event.message ?? "No message"}</p>
          </article>
        ))}
      </div>
    </DataCard>
  );
}

function AutoApprovalRule() {
  const checks = [
    "Claim amount is under $5,000",
    "Policy is active for more than 1 year",
    "Customer has no fraud flag",
  ];

  return (
    <DataCard
      title="Auto-approval rule"
      subtitle="Core business logic - not changed in this demo"
    >
      <div className="rounded-3xl bg-slate-950 p-4 text-white">
        <p className="text-xs font-semibold uppercase tracking-[0.22em] text-blue-200">
          Rules & Decisioning
        </p>
        <p className="mt-3 text-lg font-semibold">
          Approve only when all checks pass
        </p>
      </div>
      <div className="mt-4 space-y-3">
        {checks.map((check) => (
          <div
            key={check}
            className="flex items-center gap-3 rounded-2xl border border-slate-200 p-3 text-sm"
          >
            <span className="grid size-6 place-items-center rounded-full bg-emerald-100 text-xs font-bold text-emerald-700">
              OK
            </span>
            <span>{check}</span>
          </div>
        ))}
      </div>
      <p className="mt-4 text-sm text-slate-500">
        Customer Claims calls this workspace at runtime before updating the claim.
      </p>
    </DataCard>
  );
}

function CustomerSummary({ claim360 }: { claim360: Claim360 | null }) {
  const customer = claim360?.customer_local;
  return (
    <DataCard title="Customer 360" subtitle="Loaded through selected claim">
      <div className="flex items-center gap-4">
        <div className="grid size-14 place-items-center rounded-full bg-blue-100 text-xl font-semibold text-blue-700">
          {initials(customer ? customerName(customer) : "HC")}
        </div>
        <div>
          <p className="text-xl font-semibold">
            {customer ? customerName(customer) : "No customer loaded"}
          </p>
          <p className="text-sm text-slate-500">{customer?.email ?? "-"}</p>
        </div>
      </div>
      <dl className="mt-6 space-y-4 text-sm">
        <InfoRow label="Customer ID" value={customer?.id ? String(customer.id) : "-"} />
        <InfoRow label="Policy" value={customer?.policy_number ?? "-"} />
        <InfoRow label="Phone" value={customer?.phone ?? "-"} />
        <InfoRow label="Policy source" value={claim360 ? "Snowflake" : "Not loaded"} />
      </dl>
    </DataCard>
  );
}

function ServiceActivity({ claim360 }: { claim360: Claim360 | null }) {
  const rows = [
    {
      name: "Policy data",
      source: "Snowflake Get Customer Data",
      result: claim360?.policy_data?.customer_data ? "Policy context loaded" : "Pending claim 360",
    },
    {
      name: "Rules & Decisioning",
      source: "Auto-approval + routing rules",
      result: claim360?.claim.assigned_queue
        ? `${claim360.claim.assigned_queue.replaceAll("_", " ")} selected`
        : "Decision returned after evaluation",
    },
    {
      name: "Escalation & payouts",
      source: "Datadog log event + record metric",
      result: `${extractItems(claim360?.escalation_payouts?.payouts).length} payout records connected`,
    },
  ];

  return (
    <DataCard title="Enterprise stack activity" subtitle="Snowflake, Datadog, and Xano workspaces">
      <div className="space-y-3">
        {rows.map((row) => (
          <article key={row.source} className="rounded-3xl border border-slate-200 p-4">
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="font-semibold">{row.name}</p>
                <p className="mt-1 text-sm text-slate-500">{row.result}</p>
              </div>
              <span className="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700">
                {claim360 ? "Live" : "Pending"}
              </span>
            </div>
            <p className="mt-3 font-mono text-xs text-slate-400">{row.source}</p>
          </article>
        ))}
      </div>
    </DataCard>
  );
}

function policyContextFromClaim360(claim360: Claim360 | null): {
  coverage_tier?: string;
  summary?: string;
} {
  const customerData = claim360?.policy_data?.customer_data;
  if (!customerData || typeof customerData !== "object") return {};

  const record = customerData as Record<string, unknown>;
  return {
    coverage_tier:
      typeof record.coverage_tier === "string" ? record.coverage_tier : undefined,
    summary: typeof record.summary === "string" ? record.summary : undefined,
  };
}

function DataCard({
  title,
  subtitle,
  action,
  children,
}: {
  title: string;
  subtitle: string;
  action?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-[2rem] border border-slate-200 bg-white shadow-sm">
      <div className="flex flex-col gap-4 border-b border-slate-200 p-5 md:flex-row md:items-start md:justify-between">
        <div>
          <h2 className="text-xl font-semibold">{title}</h2>
          <p className="mt-1 text-sm text-slate-500">{subtitle}</p>
        </div>
        {action}
      </div>
      <div className="p-5">{children}</div>
    </section>
  );
}

function DataTable<T>({
  rows,
  columns,
  emptyText,
  loading = false,
  loadingText = "Loading data...",
  renderRow,
}: {
  rows: T[];
  columns: string[];
  emptyText: string;
  loading?: boolean;
  loadingText?: string;
  renderRow: (row: T) => React.ReactNode;
}) {
  if (loading) {
    return (
      <div className="p-6">
        <LoadingPanel text={loadingText} compact />
      </div>
    );
  }

  if (rows.length === 0) {
    return <div className="p-6 text-sm text-slate-500">{emptyText}</div>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[760px] text-left text-sm">
        <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
          <tr>
            {columns.map((column) => (
              <th key={column} className="px-5 py-3">
                {column}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">{rows.map(renderRow)}</tbody>
      </table>
    </div>
  );
}

function LoadingPanel({
  text,
  compact = false,
}: {
  text: string;
  compact?: boolean;
}) {
  return (
    <div
      className={`flex items-center gap-3 rounded-3xl border border-blue-100 bg-blue-50 text-blue-700 ${
        compact ? "p-4" : "mb-6 p-5"
      }`}
    >
      <LoadingSpinner />
      <div>
        <p className="text-sm font-semibold">{text}</p>
        <p className="mt-1 text-xs text-blue-600/80">
          Fetching live workspace data from Xano.
        </p>
      </div>
    </div>
  );
}

function LoadingSpinner({ tone = "default" }: { tone?: "default" | "light" }) {
  return (
    <svg
      aria-hidden="true"
      className={`size-5 shrink-0 animate-spin ${
        tone === "light" ? "text-white" : "text-blue-600"
      }`}
      viewBox="0 0 24 24"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
        fill="none"
      />
      <path
        className="opacity-90"
        fill="currentColor"
        d="M4 12a8 8 0 0 1 8-8v4a4 4 0 0 0-4 4H4z"
      />
    </svg>
  );
}

function Cell({
  children,
  strong = false,
  align = "left",
}: {
  children: React.ReactNode;
  strong?: boolean;
  align?: "left" | "right";
}) {
  return (
    <td
      className={`px-5 py-4 capitalize ${strong ? "font-semibold" : "text-slate-600"} ${
        align === "right" ? "text-right" : ""
      }`}
    >
      {children}
    </td>
  );
}

function Metric({
  label,
  value,
  loading = false,
}: {
  label: string;
  value: string;
  loading?: boolean;
}) {
  return (
    <article className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <p className="text-sm font-medium text-slate-500">{label}</p>
      <p className="mt-2 inline-flex items-center gap-3 text-2xl font-semibold">
        {loading && <LoadingSpinner />}
        <span>{value}</span>
      </p>
    </article>
  );
}

function HeroStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-3xl border border-white/10 bg-white/10 p-5">
      <p className="text-sm text-slate-400">{label}</p>
      <p className="mt-2 text-2xl font-semibold">{value}</p>
    </div>
  );
}

function TextField({
  label,
  value,
  onChange,
  type = "text",
  autoComplete,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  autoComplete?: string;
  placeholder?: string;
}) {
  return (
    <label className="mt-6 block text-sm font-medium text-slate-600">
      {label}
      <input
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="mt-2 w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
        type={type}
        autoComplete={autoComplete}
        placeholder={placeholder}
      />
    </label>
  );
}

function StatusPill({ value }: { value: string }) {
  return (
    <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold capitalize text-slate-700">
      {value.replaceAll("_", " ")}
    </span>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4">
      <dt className="text-slate-500">{label}</dt>
      <dd className="text-right font-semibold text-slate-900">{value}</dd>
    </div>
  );
}

function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="rounded-3xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700">
      {message}
    </div>
  );
}

function ErrorInline({ message }: { message: string }) {
  return (
    <div className="mt-5 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
      {message}
    </div>
  );
}

function pageDescription(page: Page) {
  const descriptions: Record<Page, string> = {
    claims:
      "Review customer claims, inspect the unchanged auto-approval rule, and route exceptions to specialist queues.",
    customers:
      "Browse customer records from the claims workspace using the authenticated customer endpoint.",
    payments:
      "Review claim-related invoices and payout records from the escalation and payouts workspace.",
    messages:
      "Inspect escalation telemetry and Datadog-style event receipts.",
    systems:
      "See the four insurance workspaces for the recorded setup slide and customer-claims build sequence.",
  };
  return descriptions[page];
}

function pageLabel(page: Page) {
  return navItems.find((item) => item.id === page)?.label ?? page;
}

function customerName(customer: Customer) {
  return `${customer.first_name ?? ""} ${customer.last_name ?? ""}`.trim() || `Customer ${customer.id}`;
}

function extractItems(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (value && typeof value === "object" && "items" in value) {
    const items = (value as { items?: unknown }).items;
    return Array.isArray(items) ? items : [];
  }
  return [];
}

function initials(name: string) {
  const parts = name.split(" ").filter(Boolean);
  return parts.length === 0
    ? "HC"
    : parts
        .slice(0, 2)
        .map((part) => part[0]?.toUpperCase())
        .join("");
}

function formatCurrency(value: number) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(Number(value ?? 0));
}

function formatQueue(value?: string | null) {
  if (!value || value === "unassigned") return "-";
  return value.replaceAll("_", " ");
}

function wait(ms: number) {
  return new Promise((resolve) => window.setTimeout(resolve, ms));
}

function formatDate(value?: string | number | null) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}

function errorMessage(caught: unknown) {
  return caught instanceof Error
    ? caught.message
    : "Something went wrong while contacting Xano.";
}

function isAuthFailureMessage(message: string) {
  const lower = message.toLowerCase();
  return (
    message.includes("401") ||
    lower.includes("unauthorized") ||
    lower.includes("access denied") ||
    lower.includes("invalid token")
  );
}

function escalationErrorMessage(caught: unknown) {
  const message = errorMessage(caught);
  const lower = message.toLowerCase();

  if (
    lower.includes("404") ||
    lower.includes("not found") ||
    lower.includes("unable to find") ||
    lower.includes("no api")
  ) {
    return "Escalation is not deployed yet. Push the escalation endpoint to sandbox, review it, then promote it to enable this action.";
  }

  return message;
}

export default App;
