# Sprint 19: Platform Branding & White-Labeling

## Sprint Goal

Enable configurable platform branding and organization-level white-labeling to support:
1. Easy platform rebranding (switch "Ledgoria" to any name)
2. SaaS customer white-labeling (customers apply their own brand)

---

## Business Value

| Stakeholder | Value |
|-------------|-------|
| Platform Owner | Rebrand entire platform without code changes |
| SaaS Customers | Full white-label career sites and candidate communications |
| Candidates | Consistent branded experience matching employer |
| Sales | Premium white-label tier as upsell opportunity |

---

## Architecture: Two-Tier Branding

```
┌─────────────────────────────────────────────────────────────────┐
│                     Platform Branding                           │
│  (Configurable via ENV/config - affects admin UI, defaults)     │
├─────────────────────────────────────────────────────────────────┤
│  PLATFORM_NAME = "Ledgoria"                                     │
│  PLATFORM_DOMAIN = "ledgoria.com"                               │
│  PLATFORM_LOGO = "/assets/ledgoria-logo.svg"                    │
│  PLATFORM_PRIMARY_COLOR = "#0d6efd"                             │
│  PLATFORM_SUPPORT_EMAIL = "support@ledgoria.com"                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Organization Branding                          │
│  (Database-driven - per-customer white-labeling)                │
├─────────────────────────────────────────────────────────────────┤
│  OrganizationBranding (existing model, enhanced)                │
│  - Career site: logo, colors, fonts, custom CSS                 │
│  - Emails: from address, footer, logo                           │
│  - PDF reports: header/footer branding                          │
│  - Custom domain support                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## User Stories

### Epic 1: Platform Branding Configuration

**US-1901: Platform Brand Settings**
> As a platform operator, I want to configure the platform name and branding via environment/config so I can rebrand without code changes.

Acceptance Criteria:
- [ ] `PlatformBrand` configuration class reads from ENV with defaults
- [ ] Platform name, domain, logo, colors, support email configurable
- [ ] All hardcoded "Ledgoria" references use `PlatformBrand.name`
- [ ] Admin UI navbar/title uses platform branding
- [ ] PWA manifest uses platform branding as default

**US-1902: Platform Brand Helper**
> As a developer, I want a consistent helper for accessing platform brand values so branding is DRY across views and mailers.

Acceptance Criteria:
- [ ] `PlatformBrandHelper` module with `platform_name`, `platform_logo`, etc.
- [ ] Available in views, mailers, and controllers
- [ ] Fallback chain: Organization branding → Platform branding → Hardcoded defaults

---

### Epic 2: Career Site White-Labeling

**US-1903: Apply Brand Colors to Career Site**
> As an organization admin, I want my brand colors applied to my career site so candidates see our visual identity.

Acceptance Criteria:
- [ ] Career site layout injects OrganizationBranding CSS variables
- [ ] Hero section uses brand primary/secondary colors (not hardcoded gradient)
- [ ] Buttons, links, badges use brand accent color
- [ ] `custom_css` field applied to career site pages
- [ ] Preview branding changes before publishing

**US-1904: Career Site Logo & Media**
> As an organization admin, I want my logo and cover image displayed on my career site.

Acceptance Criteria:
- [ ] Organization logo displayed in career site navbar
- [ ] Cover image used as hero background (with color overlay)
- [ ] Favicon served from organization branding
- [ ] Fallback to platform branding if org has none

**US-1905: Career Site Font Customization**
> As an organization admin, I want to use my brand fonts on my career site.

Acceptance Criteria:
- [ ] `font_family` applied to body text
- [ ] `heading_font_family` applied to headings
- [ ] Google Fonts URL field for web font loading
- [ ] Safe fallback to system fonts

---

### Epic 3: Email White-Labeling

**US-1906: Branded Email Templates**
> As an organization admin, I want candidate emails to show my company branding, not the platform branding.

Acceptance Criteria:
- [ ] Email header includes organization logo
- [ ] Email footer uses organization name, not "Ledgoria System"
- [ ] Brand primary color applied to email buttons/CTAs
- [ ] `email_footer_text` field for custom footer message

**US-1907: Custom Email From Address**
> As an organization admin, I want emails to come from my domain so candidates trust the communication.

Acceptance Criteria:
- [ ] `custom_email_domain` field on OrganizationBranding
- [ ] `custom_from_address` field (e.g., "careers@acme.com")
- [ ] DNS verification workflow for custom domains
- [ ] Fallback to platform email if custom domain not verified

**US-1908: Internal Email Branding**
> As an HR admin, I want compliance emails (I-9, work authorization) to use my organization's branding.

Acceptance Criteria:
- [ ] I-9 mailer templates use organization branding
- [ ] Work authorization emails use organization branding
- [ ] "Powered by [Platform]" footer optional/configurable

---

### Epic 4: PDF Report Branding

**US-1909: Branded PDF Reports**
> As a compliance officer, I want PDF reports to show my organization's branding for professional presentation.

Acceptance Criteria:
- [ ] PDF header includes organization logo
- [ ] PDF footer shows organization name (not "Generated by Ledgoria")
- [ ] Brand colors applied to charts and accents
- [ ] Option to include/exclude "Powered by [Platform]"

---

### Epic 5: Subdomain & Domain Routing

**US-1910: Subdomain-Based Career Sites**
> As an organization, I want my career site at `careers.acme.com` or `acme.ledgoria.com`.

Acceptance Criteria:
- [ ] Career site routes resolve organization from subdomain
- [ ] `subdomain` field on Organization model
- [ ] Subdomain uniqueness validation
- [ ] Default format: `{subdomain}.{platform_domain}`

**US-1911: Custom Domain Support**
> As a premium customer, I want my career site on my own domain (careers.acme.com).

Acceptance Criteria:
- [ ] `custom_domain` field on Organization
- [ ] DNS CNAME verification workflow
- [ ] SSL certificate provisioning (or documentation for manual setup)
- [ ] Domain uniqueness validation

---

### Epic 6: Admin UI Branding Context

**US-1912: Organization Context in Admin UI**
> As an admin user, I want to see which organization I'm managing and its branding in the admin UI.

Acceptance Criteria:
- [ ] Organization name/logo in admin sidebar
- [ ] Organization switcher for multi-org users
- [ ] Admin UI accent color from organization branding (optional)

**US-1913: Branding Preview**
> As an organization admin, I want to preview branding changes before they go live.

Acceptance Criteria:
- [ ] Live preview in branding settings page
- [ ] Preview mode for career site with draft branding
- [ ] Side-by-side comparison (current vs. proposed)

---

## Data Model Changes

### OrganizationBranding Enhancements

```ruby
# New fields to add via migration
add_column :organization_brandings, :google_fonts_url, :string
add_column :organization_brandings, :email_footer_text, :text
add_column :organization_brandings, :custom_from_address, :string
add_column :organization_brandings, :custom_email_domain, :string
add_column :organization_brandings, :email_domain_verified, :boolean, default: false
add_column :organization_brandings, :report_footer_text, :string
add_column :organization_brandings, :show_powered_by, :boolean, default: true
add_column :organization_brandings, :internal_logo, :attachment # via Active Storage
```

### Organization Enhancements

```ruby
# New fields for domain routing
add_column :organizations, :subdomain, :string
add_column :organizations, :custom_domain, :string
add_column :organizations, :custom_domain_verified, :boolean, default: false

add_index :organizations, :subdomain, unique: true
add_index :organizations, :custom_domain, unique: true
```

### New: PlatformBrand Configuration

```ruby
# config/initializers/platform_brand.rb
class PlatformBrand
  class << self
    def name
      ENV.fetch("PLATFORM_NAME", "Ledgoria")
    end

    def domain
      ENV.fetch("PLATFORM_DOMAIN", "ledgoria.com")
    end

    def logo_path
      ENV.fetch("PLATFORM_LOGO", "ledgoria-logo.svg")
    end

    def primary_color
      ENV.fetch("PLATFORM_PRIMARY_COLOR", "#0d6efd")
    end

    def support_email
      ENV.fetch("PLATFORM_SUPPORT_EMAIL", "support@ledgoria.com")
    end

    def default_from_email
      "noreply@#{domain}"
    end
  end
end
```

---

## Technical Implementation

### 1. BrandingContext Concern

```ruby
# app/controllers/concerns/branding_context.rb
module BrandingContext
  extend ActiveSupport::Concern

  included do
    before_action :set_branding_context
    helper_method :current_branding, :platform_brand
  end

  private

  def set_branding_context
    @branding = current_organization&.branding || NullBranding.new
  end

  def current_branding
    @branding
  end

  def platform_brand
    PlatformBrand
  end
end
```

### 2. Career Site Subdomain Routing

```ruby
# config/routes.rb
constraints SubdomainConstraint.new do
  scope module: :career_site do
    root to: "home#index"
    resources :jobs, only: [:index, :show]
    # ...
  end
end

# lib/constraints/subdomain_constraint.rb
class SubdomainConstraint
  def matches?(request)
    subdomain = request.subdomain
    subdomain.present? &&
      subdomain != "www" &&
      subdomain != "admin" &&
      Organization.exists?(subdomain: subdomain)
  end
end
```

### 3. Branded Email Layout

```erb
<!-- app/views/layouts/mailer.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <style>
    .button { background-color: <%= @branding&.primary_color || PlatformBrand.primary_color %>; }
  </style>
</head>
<body>
  <% if @branding&.logo&.attached? %>
    <%= image_tag url_for(@branding.logo), height: 40 %>
  <% else %>
    <%= image_tag PlatformBrand.logo_path, height: 40 %>
  <% end %>

  <%= yield %>

  <footer>
    <%= @branding&.email_footer_text || "Sent via #{PlatformBrand.name}" %>
    <% if @branding&.show_powered_by? %>
      <br>Powered by <%= PlatformBrand.name %>
    <% end %>
  </footer>
</body>
</html>
```

---

## Sprint Breakdown

### Week 1: Foundation

| Story | Points | Priority |
|-------|--------|----------|
| US-1901: Platform Brand Settings | 5 | P1 |
| US-1902: Platform Brand Helper | 3 | P1 |
| US-1910: Subdomain Routing | 8 | P1 |

**Deliverable:** Platform branding configurable, subdomain routing works

### Week 2: Career Site Branding

| Story | Points | Priority |
|-------|--------|----------|
| US-1903: Brand Colors to Career Site | 5 | P1 |
| US-1904: Logo & Media | 3 | P1 |
| US-1905: Font Customization | 3 | P2 |

**Deliverable:** Career sites fully white-labeled with org branding

### Week 3: Email & PDF Branding

| Story | Points | Priority |
|-------|--------|----------|
| US-1906: Branded Email Templates | 5 | P1 |
| US-1907: Custom Email From Address | 5 | P2 |
| US-1908: Internal Email Branding | 3 | P2 |
| US-1909: Branded PDF Reports | 5 | P2 |

**Deliverable:** Emails and reports use organization branding

### Week 4: Advanced Features

| Story | Points | Priority |
|-------|--------|----------|
| US-1911: Custom Domain Support | 8 | P3 |
| US-1912: Admin UI Branding Context | 3 | P2 |
| US-1913: Branding Preview | 5 | P3 |

**Deliverable:** Custom domains, admin context, preview functionality

---

## Sprint Totals

| Metric | Value |
|--------|-------|
| Total Stories | 13 |
| Total Points | 61 |
| P1 (Must Have) | 24 points |
| P2 (Should Have) | 21 points |
| P3 (Nice to Have) | 16 points |
| Estimated Duration | 4 weeks |

---

## Definition of Done

- [ ] All P1 stories implemented and tested
- [ ] Platform name can be changed via ENV without code changes
- [ ] Career site displays organization branding (colors, logo, fonts)
- [ ] Candidate emails use organization branding
- [ ] Subdomain routing resolves correct organization
- [ ] Migration adds new branding fields
- [ ] Admin UI for managing all branding settings
- [ ] Unit tests for PlatformBrand configuration
- [ ] Integration tests for subdomain routing
- [ ] System tests for career site branding

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Custom domains require DNS/SSL complexity | High | Document manual setup, defer auto-provisioning |
| Email deliverability with custom from address | Medium | Require SPF/DKIM verification |
| CSS injection via custom_css | High | Sanitize CSS, CSP headers |
| Performance of branding lookups | Low | Cache branding in request context |

---

## Out of Scope (Future)

- Automated SSL certificate provisioning (Let's Encrypt)
- Email domain warmup/reputation management
- A/B testing of branding variations
- Branding templates/presets
- Multi-language branding content
