import type { AuthSession } from "../types/demo";

const baseUrl =
  import.meta.env.VITE_XANO_BASE_URL ?? "https://xjik-uiot-gpzk.n7d.xano.io";

type LoginInput = {
  email: string;
  password: string;
};

type SignupInput = LoginInput & {
  name: string;
  role: "agent" | "supervisor" | "admin";
};

export type Claim = {
  id: number;
  created_at?: string;
  claim_number: string;
  customer_id: number;
  assigned_agent_id?: number | null;
  assigned_queue?: string | null;
  claim_type: string;
  status: string;
  priority: string;
  amount_requested: number;
  amount_approved?: number | null;
  summary: string;
  opened_at?: string;
  closed_at?: string | null;
  sla_due_at?: string | null;
  source?: "snowflake" | string;
};

type SnowflakeClaimRow = {
  CLAIM_ID: number;
  CLAIM_NUMBER: string;
  CUSTOMER_ID: number;
  CLAIM_TYPE: string;
  CLAIM_STATUS: string;
  CLAIM_PRIORITY: string;
  ASSIGNED_QUEUE?: string | null;
  AMOUNT_REQUESTED: number;
  SUMMARY?: string;
  OPENED_AT?: string;
};

export type Customer = {
  id: number;
  created_at?: string | number;
  first_name?: string;
  last_name?: string;
  email?: string;
  phone?: string;
  policy_number?: string;
  address?: unknown;
};

export type Invoice = {
  id: number;
  created_at?: string | number;
  customer_id: number;
  claim_ref?: string | null;
  direction?: string;
  amount: number;
  currency?: string;
  status?: string;
  description?: string | null;
  due_at?: string | number | null;
  paid_at?: string | number | null;
};

export type Notification = {
  id: number;
  created_at?: string | number;
  customer_id?: number;
  recipient?: string;
  channel?: string;
  template_name?: string;
  subject?: string | null;
  body?: string;
  status?: string;
  source?: string | null;
  sent_at?: string | number | null;
  claim_id?: number;
  claim_number?: string;
  route?: string;
  priority?: string;
  datadog_event?: string;
  datadog_metric?: string;
};

export type ClaimEvent = {
  id: number;
  created_at?: string;
  claim_id: number;
  actor_id?: number | null;
  event_type: string;
  message?: string | null;
  payload?: unknown;
};

export type ListResponse<T> = {
  items?: T[];
  itemsTotal?: number;
  pageTotal?: number;
  curPage?: number;
  source?: string;
};

export type Claim360 = {
  claim: Claim;
  customer_local?: Customer | null;
  assigned_agent?: {
    id: number;
    name: string;
    email: string;
    role: string;
  } | null;
  timeline?: ClaimEvent[];
  profiling?: {
    _source: "gartner-profiling";
    data?: unknown;
  };
  billing?: {
    _source: "gartner-billing";
    invoices?: unknown;
  };
  notifications?: {
    _source: "gartner-notify";
    sent?: unknown;
  };
  policy_data?: {
    _source: "gartner-policy-data";
    customer_data?: unknown;
    claim_history?: unknown;
  };
  rules_decisioning?: {
    _source: "gartner-rules-decisioning";
    decision?: unknown;
  };
  escalation_payouts?: {
    _source: "gartner-escalation-payouts";
    payouts?: unknown;
  };
};

export type EscalateClaimResponse = {
  claim: Claim;
  rules_decision?: unknown;
  route?: string;
  priority?: string;
  snowflake?: unknown;
  datadog?: unknown;
  escalation_record?: unknown;
  escalated_at?: string | number;
  sla_due_at?: string | number | null;
};

async function xanoFetch<T>(
  canonical: string,
  path: string,
  init: RequestInit & { token?: string } = {},
): Promise<T> {
  const { token, ...requestInit } = init;
  const response = await fetch(`${baseUrl}/api:${canonical}${path}`, {
    ...requestInit,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...requestInit.headers,
    },
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(message || `${response.status} ${response.statusText}`);
  }

  return response.json() as Promise<T>;
}

export const xanoClient = {
  baseUrl,

  async login(input: LoginInput): Promise<AuthSession> {
    return xanoFetch<AuthSession>("gartner-claims-auth", "/login", {
      method: "POST",
      body: JSON.stringify({
        email: input.email,
        password: input.password,
      }),
    });
  },

  async signup(input: SignupInput): Promise<AuthSession> {
    return xanoFetch<AuthSession>("gartner-claims-auth", "/signup", {
      method: "POST",
      body: JSON.stringify(input),
    });
  },

  async listClaims(token: string): Promise<ListResponse<Claim>> {
    const response = await xanoFetch<ListResponse<SnowflakeClaimRow> & { source?: string }>(
      "gartner-policy-data",
      "/claims",
      { token },
    );

    return {
      ...response,
      items: (response.items ?? []).map((row) => ({
        id: row.CLAIM_ID,
        claim_number: row.CLAIM_NUMBER,
        customer_id: row.CUSTOMER_ID,
        claim_type: row.CLAIM_TYPE,
        status: row.CLAIM_STATUS,
        priority: row.CLAIM_PRIORITY,
        assigned_queue: row.ASSIGNED_QUEUE,
        amount_requested: Number(row.AMOUNT_REQUESTED ?? 0),
        summary: row.SUMMARY ?? "Snowflake-backed claim record",
        opened_at: row.OPENED_AT,
        source: response.source ?? "snowflake",
      })),
    };
  },

  async listCustomers(token: string): Promise<ListResponse<Customer>> {
    return xanoFetch<ListResponse<Customer>>("gartner-claims", "/customers", {
      token,
    });
  },

  async getClaim360(claimId: number, token: string): Promise<Claim360> {
    return xanoFetch<Claim360>("gartner-claims", `/claims/${claimId}/360`, {
      token,
    });
  },

  async escalateClaim(
    claimId: number,
    token: string,
    reason: string,
  ): Promise<EscalateClaimResponse> {
    return xanoFetch<EscalateClaimResponse>("gartner-claims", `/claims/${claimId}/escalate`, {
      method: "POST",
      token,
      body: JSON.stringify({ reason }),
    });
  },

  async listInvoices(): Promise<ListResponse<Invoice>> {
    return xanoFetch<ListResponse<Invoice>>("gartner-escalation-payouts", "/payouts");
  },

  async listNotifications(): Promise<ListResponse<Notification>> {
    return xanoFetch<ListResponse<Notification>>("gartner-escalation-payouts", "/events");
  },
};
