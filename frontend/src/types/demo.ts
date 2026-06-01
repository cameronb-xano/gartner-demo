export type WorkspaceId =
  | "customerClaims"
  | "policyData"
  | "rulesDecisioning"
  | "escalationPayouts";

export type Workspace = {
  id: WorkspaceId;
  name: string;
  canonical: string;
  role: string;
  health: "Ready" | "Running" | "Promoted";
  endpointCount: number;
};

export type AuthSession = {
  token: string;
  user: {
    id: number;
    name: string;
    email: string;
    role: string;
  };
};

export type ClaimSummary = {
  claimId: number;
  customerName: string;
  status: string;
  amount: number;
  priority: "Low" | "Medium" | "High";
  assignedTeam: string;
};

export type ServiceCall = {
  workspace: WorkspaceId;
  label: string;
  endpoint: string;
  status: number;
  durationMs: number;
  result: string;
};

export type DebugRun = {
  traceId: string;
  environment: "sandbox" | "production";
  endpoint: string;
  status: number;
  durationMs: number;
  response: {
    claim: ClaimSummary;
    riskScore: number;
    invoices: number;
    notifications: number;
  };
  calls: ServiceCall[];
};
