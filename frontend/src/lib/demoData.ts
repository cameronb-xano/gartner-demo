import type { ClaimSummary, DebugRun, Workspace } from "../types/demo";

export const workspaces: Workspace[] = [
  {
    id: "customerClaims",
    name: "Customer Claims",
    canonical: "gartner-claims",
    role: "Intake, status, history, and claim decision orchestration.",
    health: "Running",
    endpointCount: 12,
  },
  {
    id: "policyData",
    name: "Policy Data",
    canonical: "snowflake-policy",
    role: "Policy lookup, coverage checks, and eligibility context.",
    health: "Ready",
    endpointCount: 2,
  },
  {
    id: "rulesDecisioning",
    name: "Rules & Decisioning",
    canonical: "gartner-rules-decisioning",
    role: "Auto-approval and specialist routing decisions outside the claims service.",
    health: "Ready",
    endpointCount: 2,
  },
  {
    id: "escalationPayouts",
    name: "Escalation & Payouts",
    canonical: "datadog-payouts",
    role: "Exception routing, supervisor review, and approved disbursements.",
    health: "Ready",
    endpointCount: 3,
  },
];

export const featuredClaim: ClaimSummary = {
  claimId: 1042,
  customerName: "Maya Chen",
  status: "Escalated review",
  amount: 18420,
  priority: "High",
  assignedTeam: "Complex Claims",
};

export const sandboxRun: DebugRun = {
  traceId: "dbg_sandbox_7f31",
  environment: "sandbox",
  endpoint: "GET /api:gartner-claims/claims/1042/360",
  status: 200,
  durationMs: 186,
  response: {
    claim: featuredClaim,
    riskScore: 82,
    invoices: 2,
    notifications: 4,
  },
  calls: [
    {
      workspace: "customerClaims",
      label: "Load claim",
      endpoint: "GET /api:gartner-claims/claims/1042",
      status: 200,
      durationMs: 31,
      result: "Claim CLM-2026-01042 selected",
    },
    {
      workspace: "policyData",
      label: "Pull policy context",
      endpoint: "Snowflake Get Customer Data (claimId)",
      status: 200,
      durationMs: 42,
      result: "Active policy, comprehensive coverage",
    },
    {
      workspace: "rulesDecisioning",
      label: "Evaluate business rules",
      endpoint: "POST /api:gartner-rules-decisioning/decisions/evaluate",
      status: 200,
      durationMs: 55,
      result: "Escalate to property specialist",
    },
    {
      workspace: "escalationPayouts",
      label: "Record observability",
      endpoint: "Datadog log event + record metric",
      status: 200,
      durationMs: 58,
      result: "Escalation event and metric accepted",
    },
  ],
};

export const productionRun: DebugRun = {
  ...sandboxRun,
  traceId: "dbg_prod_c91a",
  environment: "production",
  durationMs: 142,
};
