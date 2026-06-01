# Gartner Xano Demo Frontend

Tailwind CSS application for demonstrating the recorded insurance claims workflow:

- Auth through the `gartner-claims-auth` API.
- Customer Claims, Policy Data, Rules & Decisioning, and Escalation & Payouts workspace views.
- Escalation routing with Snowflake-style policy context and Datadog-style telemetry.
- Production verification for the recorded demo.

## Run

```bash
npm install
npm run dev
```

## Environment

Copy `.env.example` to `.env.local` if you want to change the API target.

```bash
VITE_XANO_BASE_URL=https://xjik-uiot-gpzk.n7d.xano.io
VITE_DEMO_MODE=true
```

`VITE_DEMO_MODE=true` keeps the demo reliable with sample responses. Set it to
`false` to call the live Xano APIs directly.
