# App Store Optimization — Master Guide (2025-2026)

Complete ASO research for the moranetz iOS portfolio. This is the single reference doc for all App Store submissions.

---

## Table of Contents
1. [How Apple Search Ranking Works](#1-how-apple-search-ranking-works)
2. [Title, Subtitle & Keywords](#2-title-subtitle--keywords)
3. [Screenshots & Preview Videos](#3-screenshots--preview-videos)
4. [App Description](#4-app-description)
5. [Ratings & Reviews](#5-ratings--reviews)
6. [Category Selection](#6-category-selection)
7. [Launch Strategy](#7-launch-strategy)
8. [Getting Featured by Apple](#8-getting-featured-by-apple)
9. [Pricing Strategy](#9-pricing-strategy)
10. [Post-Launch Playbook](#10-post-launch-playbook)
11. [Tools & Resources](#11-tools--resources)
12. [Per-App Metadata (Ready to Paste)](#12-per-app-metadata)

---

## 1. How Apple Search Ranking Works

Apple's algorithm evaluates apps across weighted signal tiers:

### Tier 1 — Metadata Relevance (Highest Weight)
- **App Title** keywords carry the most ranking weight
- **Subtitle** keywords are second-highest
- **Keyword field** (100 chars) provides additional indexing
- **NEW (June 2025):** Screenshot caption text is now indexed — Apple extracts text from captions and treats it as keyword metadata. Keywords in screenshots do NOT compete with title/subtitle/keyword field. Duplication is expected.
- **NEW (July 2025):** Custom Product Pages (CPPs) appear in organic search. Apple doubled CPP limits from 35 to 70 per app.
- **NEW (2025):** Apple auto-generates "tags" for every app using AI trained on metadata.

### Tier 2 — Download Signals
- Download velocity (installs over 24-72 hour windows)
- Total download volume for Top Charts
- Conversion rate from search impressions to installs

### Tier 3 — User Quality Signals
- Ratings (below 3.5 stars = substantially reduced visibility; above 4.0 correlates with higher rankings)
- Review volume and recency (fresh ratings carry more weight)
- Retention, session length, DAU, churn, uninstall rates
- Crash rates directly impact visibility

### Tier 4 — Maintenance Signals
- Update frequency (every 2-4 weeks recommended)
- Revenue performance
- In-App Events (indexed, can appear in search results)

**Key insight:** Apple now uses semantic understanding, not just exact keyword matching. Rankings favor apps that prove real users want them, keep them installed, and engage with them.

---

## 2. Title, Subtitle & Keywords

### The 30-30-100 Rule
| Field | Limit | Weight | Rule |
|-------|-------|--------|------|
| Title | 30 chars | Highest | Most important keyword at the BEGINNING |
| Subtitle | 30 chars | High | Complement title — NEVER duplicate words from title |
| Keywords | 100 chars | Medium | Synonyms and terms NOT in title/subtitle |

### Keyword Field Rules
- Separate with commas, NO spaces: `brain,training,memory` not `brain, training, memory`
- Only singular forms in English (Apple auto-indexes plurals)
- Never include: "app", "free", "iPhone", "iPad", "new", "best" (Apple ignores these)
- Never include your category name (already indexed from category selection)
- Never include competitor brand names (risks rejection)
- Never include filler words: "the", "and", "with", "to"
- Apple auto-combines words from Title + Subtitle + Keywords

### Keyword Research Process
1. **Apple Search Ads Discovery Campaigns** — run broad match, check Search Term Reports for real tap-through rates (most reliable method)
2. **App Store Connect Analytics** — free, shows actual search term performance
3. **Autocomplete mining** — type partial keywords in App Store search to see suggestions
4. **Competitor analysis** — what terms do top apps in your category rank for?

---

## 3. Screenshots & Preview Videos

### Screenshots
- Up to 10 per device size
- **First 3 are visible in search results** — these make or break conversion
- Can increase conversion 20-35%

### The Screenshot Text Revolution (June 2025)
Apple now indexes caption text on screenshots as a ranking factor. This is free additional keyword real estate:
- Place keyword-rich captions at the TOP of screenshots
- These keywords don't compete with your title/subtitle/keyword field
- Duplication between screenshot text and other fields is expected and fine

### What Converts Best
- Show real app UI, not abstract marketing graphics
- Lead with #1 value proposition in screenshot 1
- Social proof ("10M+ users") in early screenshots
- High contrast, bold text captions
- Blue/green conveys trust; red/orange creates urgency

### Preview Videos
- Can boost conversion 20-40%
- 15-30 seconds, show REAL in-app experience
- Video appears BEFORE screenshots in search results
- Portrait format: 7% more watch time, 5% better conversion

---

## 4. App Description

### The Hard Truth
**The iOS description is NOT indexed for search.** Zero direct impact on keyword rankings. (This is different from Google Play, which fully indexes descriptions.)

### What It's Good For
- Conversion optimization (convincing users who land on your page)
- **First 3 lines before the "more" fold** are all most users read

### First 3 Lines Strategy
- Lead with strongest value proposition
- Include social proof if available
- Clear call-to-action
- Do NOT waste on "Welcome to [App Name]" boilerplate

### Promotional Text (167 chars above description)
- Can be changed without a new app version
- NOT indexed for search
- Use for seasonal promotions, feature announcements

---

## 5. Ratings & Reviews

### Impact on Rankings
- Below 3.5 stars: substantially reduced visibility
- Above 4.0: correlates with higher keyword rankings
- 50% of users won't download an app rated 3 stars or below
- Moving 3 stars to 4 stars: up to 89% increase in conversion
- 90% of Apple-featured apps maintain 4.0+
- **Minimum viable rating: 4.0 stars**

### SKStoreReviewController Timing

**Hard constraints:**
- Max 3 prompts per user per 365 days
- Apple may suppress the prompt — you request it, Apple decides
- Cannot customize the dialog

**Optimal timing (check ALL before requesting):**
- User installed 7+ days ago
- User completed 3+ sessions minimum
- A positive event just occurred (level complete, task finished, achievement)
- NOT already prompted for this app version
- 2-second delay before showing

**Deep link for manual review requests:**
```
https://apps.apple.com/app/idYOUR_APP_ID?action=write-review
```

---

## 6. Category Selection

Primary category determines Top Charts placement. Both primary and secondary are indexed by search.

| App | Primary | Secondary | Rationale |
|-----|---------|-----------|-----------|
| CORTEX | Games > Puzzle | Education | Where Lumosity/Elevate live; Education captures self-improvement |
| Lumina | Games > Adventure | Games > Casual | Exploration fits Adventure; Casual captures cozy game browsers |
| Persuade Me | Education | Business | Skill-building category; Business targets professionals |
| WeighIt | Productivity | Business | Decision tools live here; Business expands to professionals |

---

## 7. Launch Strategy

### The 7-Day New App Boost
Apple gives all new apps enhanced keyword rankings during their first 7 days. After day 7, rankings can plummet from top 10-30 to #40-260 ("the Seven Day Cliff").

### Two-Phase Keyword Strategy
1. **Days 1-7:** Target higher-difficulty, higher-volume keywords (Apple's boost compensates)
2. **Day 8+:** Shift metadata to lower-difficulty keywords you can realistically maintain

### Stagger Launches 3-4 Weeks Apart

| Order | App | Why |
|-------|-----|-----|
| 1st (Week 1) | CORTEX | Biggest market ($16B), easiest pitch, most content |
| 2nd (Week 4-5) | WeighIt | Different category (Productivity), no audience overlap |
| 3rd (Week 8-9) | Persuade Me | Blue ocean, needs word-of-mouth time |
| 4th (Week 12+) | Lumina | Strongest emotional appeal, time with seasonal moment |

### Launch Day Checklist
- [ ] All ASO metadata optimized
- [ ] Screenshots and preview video ready
- [ ] Press kit prepared
- [ ] Social media posts scheduled for each of 7 days
- [ ] Friends/family/beta testers ready to download day 1
- [ ] Respond to every review within 24 hours during launch week

### First 72 Hours
Concentrate ALL marketing spend here. Don't spread thin over weeks.

---

## 8. Getting Featured by Apple

### What Apple's Editorial Team Evaluates
1. Beautiful UI design
2. Cohesive, efficient UX
3. Innovation — new approaches to familiar problems
4. Uniqueness — fresh approach or new genre
5. Accessibility features
6. Localization (multiple languages)
7. Compelling App Store page with positive ratings (4.0+)

### Does Using Latest APIs Help?
Apple doesn't officially favor specific technologies, but SwiftUI, SwiftData, widgets, Live Activities, and App Intents demonstrate ecosystem alignment and often produce better UX.

### How to Get Nominated
- Submit through **Featuring Nominations in App Store Connect**
- Lead time: 2 weeks minimum, 3 months recommended
- Can nominate: new apps, significant updates, in-app events
- All apps eligible regardless of age

### What Gets Featured
- 90% have 4.0+ ratings
- Align with Apple's values: accessibility, privacy, education, environment, inclusion
- Seasonal alignment (Black History Month, Earth Day, Mental Health Awareness)

---

## 9. Pricing Strategy

| App | Model | Price | Rationale |
|-----|-------|-------|-----------|
| CORTEX | Freemium + Subscription | Free / $5.99 mo / $39.99 yr | Industry standard for brain training. Lumosity/Elevate model. |
| Lumina | Premium | $3.99 one-time | Cozy game audience hates ads. Matches Alto's/Monument Valley. |
| Persuade Me | Freemium + Subscription | Free / $4.99 mo / $29.99 yr | Education apps monetize through subscriptions. Free tier builds audience for blue ocean. |
| WeighIt | Freemium + One-Time | Free / $4.99 Pro unlock | Productivity users resist subscriptions for simple tools. Higher conversion with one-time. |

### Psychology
- Annual subscription price should be ~55% of monthly price x 12 (feels like a deal)
- Free tier must be useful enough to get ratings, limited enough to convert
- One-time purchases work better for tools; subscriptions for content/training

---

## 10. Post-Launch Playbook

### The First 7 Days (Not 72 Hours)
- Days 1-3: Maximum marketing push
- Days 4-7: Sustain momentum, push for ratings
- Day 8+: Shift to lower-difficulty keywords, begin retention optimization

### Update Cadence
- Meaningful updates every 30-45 days
- Each update resets "Recently Updated" visibility
- Don't push empty updates — Apple detects them
- Pair updates with In-App Events for extra search visibility

### Responding to Reviews
- Respond to EVERY review during the first month
- Negative reviews: acknowledge, state what you're fixing, invite updated review
- Responses are public — other users read them
- Quick response times signal active, caring developer

### Redownloads > New Downloads
Apple data: redownloads outpace new downloads 2:1 weekly (839M new vs 1.9B redownloads). Retention and re-engagement are more valuable than pure acquisition.

---

## 11. Tools & Resources

### Must-Have (Free)
| Tool | Use |
|------|-----|
| App Store Connect | Baseline analytics, actual search term data |
| Apple Search Ads | Best keyword research (free to research, pay for ads) |

### Best Free Tier
| Tool | Features |
|------|----------|
| APPlyzer | Unlimited apps, 100 keyword tracking, 12 months history |
| App Radar | ASO workflow + keyword tracking |
| AppFollow | Review management + keyword tracking |

### Worth Paying For (When Revenue Justifies)
| Tool | Strength |
|------|----------|
| AppTweak | Industry standard, most comprehensive |
| Sensor Tower | Deep market intelligence |
| SplitMetrics | A/B testing focus |

---

## 12. Per-App Metadata

### CORTEX

| Field | Value |
|-------|-------|
| Title | `CORTEX - Brain Training Games` |
| Subtitle | `Sharpen Logic & Focus Daily` |
| Keywords | `brain,training,memory,puzzle,logic,focus,thinking,cognitive,mental,fitness,mind,reasoning,critical` |
| Primary Category | Games > Puzzle |
| Secondary | Education |

**Screenshot Captions:**
1. "Brain Training That Teaches Through Play"
2. "7 Interactive Reasoning Mechanics"
3. "Weigh Evidence on a Tipping Scale"
4. "Build Consequence Chains"
5. "Calibrate Your Probability Intuition"
6. "Master Persuasive Argument Structure"
7. "Track 23 Critical Thinking Concepts"
8. "Daily Challenge — 5 Questions, One Shot"

**Market:** $16.3B (2025), projected $70B by 2032
**Competitors:** Lumosity, Elevate, Peak, Brilliant
**Differentiation:** "The mechanic IS the skill — you perform reasoning, not answer quizzes."

---

### WeighIt

| Field | Value |
|-------|-------|
| Title | `WeighIt - Smart Decisions` |
| Subtitle | `Analyze Evidence, Choose Well` |
| Keywords | `decision,maker,compare,options,matrix,analysis,choose,prioritize,evidence,weigh,pro,con,thinking` |
| Primary Category | Productivity |
| Secondary | Business |

**Screenshot Captions:**
1. "CIA-Grade Decision Analysis Made Simple"
2. "Weigh Evidence Against Every Hypothesis"
3. "See Which Evidence Actually Matters"
4. "Detect Your Own Confirmation Bias"
5. "Ranked Results with Diagnostic Scoring"
6. "Export and Share Your Analysis"

**Competitors:** Decision Matrix App, Priority Matrix, Arbitrium (all weak)
**Differentiation:** "The only decision tool built on the CIA's Analysis of Competing Hypotheses."

---

### Persuade Me

| Field | Value |
|-------|-------|
| Title | `Persuade Me - Influence Coach` |
| Subtitle | `Practice Real Social Skills` |
| Keywords | `persuasion,influence,negotiation,communication,leadership,social,confidence,charisma,speaking,pitch` |
| Primary Category | Education |
| Secondary | Business |

**Screenshot Captions:**
1. "Practice Real Persuasion Skills with AI"
2. "12 Realistic Scenarios with Named Characters"
3. "Full Psychological Profiles for Each Character"
4. "Strategic Briefings with NLP Techniques"
5. "Speak Your Pitch — AI Analyzes in Real Time"
6. "Scored Checklist Ranked by Scenario Importance"
7. "See How the Character Would Actually React"
8. "Master Rewrite — How a Pro Would Open It"

**Market:** Blue ocean — no direct competitor
**Differentiation:** "The flight simulator for real-world persuasion."
**Note:** Requires privacy policy URL (microphone + external API)

---

### Lumina

| Field | Value |
|-------|-------|
| Title | `Lumina - Explore & Discover` |
| Subtitle | `A Cozy Collection Adventure` |
| Keywords | `cozy,exploration,adventure,relaxing,collect,nature,peaceful,beautiful,indie,calm,discover,creatures` |
| Primary Category | Games > Adventure |
| Secondary | Games > Casual |

**Screenshot Captions:**
1. "Explore 5 Magical Biomes"
2. "Discover 15 Unique Creatures"
3. "Collect Light Orbs and Crystals"
4. "Procedural Art — No Assets, All Beauty"
5. "Creature Codex with Lore for Every Species"
6. "Unlock New Worlds by Collecting Crystals"

**Market:** $973M (2024), projected $1.47B by 2032
**Competitors:** Alto's Odyssey, Monument Valley, Stardew Valley
**Differentiation:** "Rendered entirely with procedural Core Graphics — no sprites, no assets."

---

*Last updated: March 2026*
*Sources: AppTweak, Sensor Tower, Phiture, Appfigures, Apple Developer documentation, SplitMetrics*
