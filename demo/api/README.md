# demoauth

💧 A project built with the Vapor web framework.

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

## Configuring Email Transport

By default the demo API prints outgoing emails (including password-reset links) to the
server terminal via Vapor's structured logger. This is convenient for local development:
copy the reset link directly from the terminal output.

To send **real** emails, set the `RESEND_API_KEY` environment variable before starting
the server. [Resend](https://resend.com) has a free tier and requires no credit card.

### Quick start with Resend

1. Sign up at [resend.com](https://resend.com) and create an API key in the dashboard.
2. Copy `.env.example` to `.env` and fill in your key:
   ```
   RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxx
   RESEND_FROM_EMAIL=onboarding@resend.dev
   ```
3. Start the server — it will automatically use the Resend transport.

### Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RESEND_API_KEY` | No | _(console logger used)_ | Resend API key. When set, emails are sent via Resend instead of stdout. |
| `RESEND_FROM_EMAIL` | No | `onboarding@resend.dev` | Sender address. See free-tier note below. |

### Free-tier limitation

Resend's built-in test address `onboarding@resend.dev` only delivers emails to the
address registered with your Resend account. This is sufficient for demo purposes — you
receive the reset link in your own inbox.

To send to **any** address, verify a custom domain in the Resend dashboard
(Settings → Domains) and set `RESEND_FROM_EMAIL` to an address on that domain, for
example `noreply@yourdomain.com`.

### How the transport is selected in configure.swift

```swift
if let resendAPIKey = Environment.get("RESEND_API_KEY"), !resendAPIKey.isEmpty {
    let fromEmail = Environment.get("RESEND_FROM_EMAIL") ?? "onboarding@resend.dev"
    emailTransport = makeResendEmailTransport(apiKey: resendAPIKey, fromEmail: fromEmail)
} else {
    let logger = app.logger
    emailTransport = { recipient, subject, body in
        logger.notice("[EMAIL] To: \(recipient) | Subject: \(subject) | Body: \(body)")
    }
}
```

The `makeResendEmailTransport` function in `Sources/demoauth/ResendEmailTransport.swift`
accepts an injectable `URLSession` parameter so it can be tested without real network
calls.

---

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
